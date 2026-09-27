import Foundation
import Darwin

public enum WorkspacePersistenceError: LocalizedError {
    case couldNotFindApplicationSupport
    case readFailed(Error)
    case decodeFailed(Error)
    case writeFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .couldNotFindApplicationSupport: "The Application Support folder could not be found."
        case .readFailed(let error): "Passing By could not read your workspace: \(error.localizedDescription)"
        case .decodeFailed(let error): "Passing By could not open your workspace data: \(error.localizedDescription)"
        case .writeFailed(let error): "Passing By could not save your changes: \(error.localizedDescription)"
        }
    }
}

public enum AppointmentImportError: LocalizedError {
    case invalidRows
    case unknownCategory
    case locked

    public var errorDescription: String? {
        switch self {
        case .invalidRows: "Correct all TSV errors before importing."
        case .unknownCategory: "The selected Category no longer exists. Choose another Category."
        case .locked: "Unlock Passing By before importing Appointments."
        }
    }
}

public struct WorkspacePersistence {
    public let url: URL
    public init(url: URL) { self.url = url }

    public static func standard() throws -> WorkspacePersistence {
        guard let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw WorkspacePersistenceError.couldNotFindApplicationSupport
        }
        return WorkspacePersistence(url: directory.appendingPathComponent("Passing by", isDirectory: true).appendingPathComponent("workspace.json"))
    }

    private func fileExists() throws -> Bool {
        var details = stat()
        if lstat(url.path, &details) == 0 { return true }
        if errno == ENOENT { return false }
        throw WorkspacePersistenceError.readFailed(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)))
    }

    public func load() throws -> Workspace {
        if try !fileExists() { return Workspace() }
        let data: Data
        do { data = try Data(contentsOf: url) }
        catch { throw WorkspacePersistenceError.readFailed(error) }
        do { return try JSONDecoder().decode(Workspace.self, from: data) }
        catch { throw WorkspacePersistenceError.decodeFailed(error) }
    }

    public func save(_ workspace: Workspace) throws {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(workspace)
            if try fileExists() {
                // Preserve the last readable snapshot before replacing it.
                let oldData = try Data(contentsOf: url)
                _ = try JSONDecoder().decode(Workspace.self, from: oldData)
                let backup = url.appendingPathExtension("backup")
                try oldData.write(to: backup, options: .atomic)
            }
            try data.write(to: url, options: .atomic)
        } catch { throw WorkspacePersistenceError.writeFailed(error) }
    }
}

public final class AppStore {
    public private(set) var workspace: Workspace
    public var persistenceError: String?
    public var onPersistenceError: ((String) -> Void)?
    private let persistence: WorkspacePersistence

    public init(persistence: WorkspacePersistence? = nil) throws {
        self.persistence = try persistence ?? .standard()
        self.workspace = try self.persistence.load()
        cleanUp()
    }

    public func change(_ mutation: (inout Workspace) -> Void) {
        mutation(&workspace)
        cleanUp(save: false)
        save()
    }

    public func importAppointments(_ parsed: AppointmentTSVImport, categoryID: UUID?) throws {
        guard parsed.canImport else { throw AppointmentImportError.invalidRows }
        guard categoryID == nil || workspace.labels.contains(where: { $0.id == categoryID }) else { throw AppointmentImportError.unknownCategory }
        var candidate = workspace
        candidate.dates.append(contentsOf: parsed.rows.map {
            DateItem(title: $0.title, date: $0.date, itemDescription: $0.description, labelID: categoryID)
        })
        do { try persistence.save(candidate) }
        catch {
            persistenceError = error.localizedDescription
            onPersistenceError?(error.localizedDescription)
            throw error
        }
        workspace = candidate
        persistenceError = nil
    }

    public func cleanUp(save: Bool = true) {
        let old = workspace
        workspace.purgeExpired()
        if save && old != workspace { self.save() }
    }

    @discardableResult public func flush() -> Bool {
        do { try persistence.save(workspace); persistenceError = nil }
        catch { persistenceError = error.localizedDescription; onPersistenceError?(error.localizedDescription) }
        return persistenceError == nil
    }
    private func save() { _ = flush() }
}
