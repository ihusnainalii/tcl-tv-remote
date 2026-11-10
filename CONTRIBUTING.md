# Contributing

Thanks for helping improve TCL Remote for Mac.

## Getting started

Install the tools: `brew install swiftlint swiftgen`.


1. Fork the repo and create a branch from `main` (for example `fix/volume-slider` or `feat/fire-tv`).
2. Build and run with `scripts/build.sh && open "build/TCL Remote.app"`, or open `Package.swift` in Xcode.
3. Run `swiftlint` and fix any warnings (CI runs it in strict mode).
4. User-facing text lives in `Sources/TCLRemote/Resources/en.lproj/Localizable.strings`. After editing it, run `swiftgen` and use the generated `L10n` constants instead of string literals. CI fails if `Sources/TCLRemote/Generated` is out of date.
5. Run `swift test` before you push. CI runs the same tests on every pull request, flags each failed test on the PR, and fails if TVKit line coverage drops below the floor set in `.github/workflows/ci.yml`.

Changes to `main` go through pull requests; direct pushes are blocked.

## iPhone and iPad

`brew install xcodegen`, then `cd iOS && xcodegen` and open `TCLRemote.xcodeproj` (schemes: TCL Remote iOS / watchOS / macOS). Shared UI changes go in `Sources/RemoteUI`; touch-only layout goes in `Presentation/Mobile` (compiled for iOS only). CI builds the iOS app on every pull request.

## Where code goes

- **TV protocols, discovery, rules and storage** go in `Sources/TVKit`, which has no UI. New rules belong in `TVLibrary`, a value type, and need unit tests.
- **UI and app state** go in `Sources/RemoteUI`, shared by the Mac and iOS apps. Views read from `Store`, and `Store` coordinates TVKit and the system services. `Sources/TCLRemote` and `iOS/App` are thin app shells.
- **A new TV platform** needs a driver conforming to `TVRemote`, plus `PairingCapable` and/or `StateReporting` if it supports them, and one case in `RemoteFactory`.

See [Architecture](README.md#architecture) for the full layout.

## Pull requests

- Keep each PR focused on one change, and describe what changed and how you tested it.
- Add or update tests for logic in TVKit.
- For UI changes, include a screenshot or short screen recording.
- If you tested against a real TV, say which model and OS version. That's the most valuable testing there is.

## Testing against a real TV

```bash
TV_HOST=<tv-ip> TV_CODE_FILE=/tmp/tv-code.txt swift test --filter LiveTVTests
```

If the Mac isn't paired yet, the TV shows a code. Write it into the code file to continue.

## Reporting bugs and ideas

Use the issue templates. For security problems, follow [SECURITY.md](SECURITY.md) rather than opening a public issue.

By contributing, you agree your work is licensed under the [Apache License 2.0](LICENSE) and that you'll follow the [Code of Conduct](CODE_OF_CONDUCT.md).
