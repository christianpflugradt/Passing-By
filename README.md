# Passing By

Passing By is a small native macOS workspace for temporary notes, to-dos, and appointments.

## Requirements

macOS 14 or later and the Apple Command Line Tools (`xcode-select --install`).

## Development

```sh
swift build
swift run PassingByApp
swift run PassingByTests
```

## Release app

```sh
chmod +x Scripts/build-release.sh
Scripts/build-release.sh
open "build/Passing By.app"
```

The release bundle is `build/Passing By.app`. It is ad-hoc signed for local use; drag it to `/Applications` if you want it installed there.

## Commit messages

After cloning, run `sh Scripts/setup-git-hooks.sh` to enable the repository-local commit hook. Future commits must use `type(scope): description` with a non-empty description.

Allowed types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style`, `revert`.

Allowed scopes: `app`, `ui`, `notes`, `todos`, `appointments`, `settings`, `persistence`, `security`, `build`, `release`, `docs`, `deps`, `tests`.

Examples: `feat(notes): add folding support`, `fix(ui): correct sidebar alignment`, `docs(docs): explain app lock`.
