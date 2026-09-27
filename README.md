# Passing By

Passing By is a small native macOS workspace for information that matters now: to-dos, appointments, and Markdown notes. It is local-first, keyboard-friendly, and designed to stay calm and low-distraction. See [Product.md](Product.md) for the detailed product specification.

## Features

- A compact dashboard for open to-dos and upcoming appointments.
- To-dos, date-based appointments, and editable Markdown source notes with syntax highlighting and native Find.
- Optional categories, a shared category filter, and a scheduled default category for new items.
- Appointment import from TSV, configurable retention for completed to-dos and passed appointments, and optional App Lock.

## Requirements

- macOS 14 or later.
- Apple Command Line Tools with Swift 6 or later (`xcode-select --install`); the app uses the system Swift toolchain and macOS frameworks.
- [Mise](https://mise.jdx.dev/) for the recommended development commands. No separate Node.js runtime is required to build or run the app.

## Development

From the repository root:

```sh
mise install
mise run build
mise run test
```

`mise run build` creates `build/Passing By.app`. Open that bundle from Finder to run it. The build is ad hoc signed and uses the latest reachable release tag for its version when one exists.

After cloning, run `sh Scripts/setup-git-hooks.sh` to enable the repository commit-message hook. Commit subjects use `type(scope): description` with a non-empty description.

Allowed types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style`, `revert`.

Allowed scopes: `app`, `ui`, `notes`, `todos`, `appointments`, `settings`, `persistence`, `security`, `build`, `release`, `docs`, `deps`, `tests`.

Examples: `build(build): assemble local app`, `fix(ui): correct sidebar alignment`, `docs(docs): clarify setup`.

## Releases

Download macOS builds from [GitHub Releases](https://github.com/christianpflugradt/PassingBy/releases). Each `Passing-By-<version>.zip` contains `Passing By.app`. The app is ad hoc signed and is not notarized.

Releases use Semantic Release and SemVer. Run `mise run release` to start the manual GitHub workflow; Conventional Commits determine the next version. After the build and tests pass, Semantic Release supplies that version to the app bundle and ZIP, creates the `v<version>` tag, and publishes the GitHub Release with the ZIP attached. For local packaging checks, run `RELEASE_VERSION=1.2.3 mise run package` with a test version.

## Data and privacy

The workspace is saved automatically at `~/Library/Application Support/Passing By/workspace.json`. On each subsequent save, the last readable version is copied to `workspace.json.backup`. Existing data in the former `Passing by` directory is migrated on first launch.

Optional App Lock uses native macOS authentication to protect access to the application UI. It does **not** encrypt the workspace file.

## License

Passing By is licensed under [Apache-2.0](LICENSE).
