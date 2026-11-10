# TCL Remote for Mac

A native macOS menu bar remote for TCL TVs. It finds your TV on the local network, pairs once, remembers it, and reconnects on its own, so your keyboard and trackpad become the remote.

[![CI](https://github.com/ihusnainalii/tcl-tv-remote/actions/workflows/ci.yml/badge.svg)](https://github.com/ihusnainalii/tcl-tv-remote/actions/workflows/ci.yml)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-black)
![Swift 6 toolchain](https://img.shields.io/badge/Swift-6-orange)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

| Supported TVs | Protocol | Pairing |
|---|---|---|
| TCL **Google TV** and **Android TV** | Android TV Remote v2 (TLS, ports 6466/6467) | One-time 6-character code shown on the TV |
| TCL **Roku TV** | Roku External Control Protocol (HTTP, port 8060) | None |

Fire TV editions aren't supported yet.

## Features

**Finding and connecting**
- Finds TVs automatically (Bonjour for Google/Android TV, SSDP for Roku), or add one by IP address
- Remembers every TV with a "last used" time; favorite and rename TVs
- Connects on launch to your favorite TV, or the last one you used
- Reconnects on its own when the Mac rejoins Wi-Fi, wakes from sleep, or the TV restarts, and finds the TV again if its IP address changes

**Remote**
- Power (toggle, on, off), arrow pad with OK, back, home, menu, settings, info, guide, exit, search, captions
- Volume and channel buttons, with hold-to-repeat
- Live volume bar on Google TV: drag it or swipe on the trackpad
- Play/pause, stop, rewind, fast-forward, previous, next
- HDMI 1–4, AV and Live TV inputs, plus a 0–9 keypad
- **Type** tab: a live keyboard for the TV's search and text boxes, with Return sending Enter
- App launcher with real app icons; favorite and recent apps, search, and a picker of popular TV apps for Google TV (it can't report installed apps) plus custom links

**Mac integration**
- Menu bar panel that resizes to its content, plus keyboard control (arrows, Return, Esc, Delete, Space, `+`/`−`, `M`, `H`)
- Settings inside the panel: launch at login, auto-connect, retry interval, notifications, saved TVs, reset pairing
- Color themes (7 presets or any custom color) and System/Light/Dark mode
- macOS notifications when a TV disconnects, reconnects or needs pairing
- Reduce Motion support and VoiceOver labels

## Install

### Download
Get the latest `.dmg` from [Releases](https://github.com/ihusnainalii/tcl-tv-remote/releases), open it, and drag **TCL Remote** into Applications.

Releases built without an Apple Developer ID aren't notarized, so macOS blocks the first launch. Right-click the app, choose **Open**, and confirm.

### Build from source
Requires macOS 15 or later and Xcode 16 or later.

```bash
git clone https://github.com/ihusnainalii/tcl-tv-remote.git
cd tcl-tv-remote
scripts/build.sh            # universal (Apple Silicon + Intel) build/TCL Remote.app
open "build/TCL Remote.app"
```

You can also open `Package.swift` in Xcode and run the `TCLRemote` scheme.

## First run

1. Allow **Local Network** access when macOS asks. Without it the app can't see your TV.
2. Click the remote icon in the menu bar. The app scans your network.
3. Pick your TV.
   - **Google TV / Android TV:** click **Pair**, then type the code shown on the TV.
   - **Roku TV:** it connects right away. If keys don't work, set the TV's *Settings → System → Advanced system settings → Control by mobile apps* to **Default** or **Permissive**.
4. Next time, the app connects by itself.

macOS may ask once whether TCL Remote can use the **"TCL Remote pairing certificate"** item in your Keychain. Choose **Always Allow**. Local development builds change signature on every rebuild, so macOS asks again after each one.

## Troubleshooting

| Problem | Fix |
|---|---|
| No TVs found | Check the Mac and TV are on the same network and that *System Settings → Privacy & Security → Local Network* allows TCL Remote. Guest Wi-Fi often blocks device discovery; use **Add by IP**. |
| "TV is unreachable" | The TV must be on or in network standby. Turn on the TV's option to stay connected to the network while off (often under *Settings → System → Power*). |
| Google TV asks to pair again | Use **Re-pair** in the panel, or **Settings → TVs → Reset Pairing** to start fresh. |
| Typing does nothing | Open a search or text box on the TV first. On Google TV, letters arrive in lowercase. |
| Roku ignores keys | Set *Control by mobile apps* to Default or Permissive (see above). |

## Privacy and security

- Everything happens on your local network. There's no account, no server and no analytics.
- The Google TV pairing certificate is generated on your Mac and stored in the macOS Keychain.
- Saved TVs and preferences stay in the app's local preferences.
- Network requests leave your network only for two things: app icons from Apple's public App Store lookup API (sending just the app name) and **Check for Updates** (GitHub's releases API).
- Roku's control protocol is plain HTTP by design. Google TV traffic is TLS-encrypted.

To report a vulnerability, see [SECURITY.md](SECURITY.md).

## Architecture

The code is split into two modules, and dependencies only point one way: the app depends on `TVKit`, never the reverse.

```
Sources/
  TVKit/                       core library: no UI, unit-tested
    Domain/                    TV, KnownTV, TVApp, Key, TVError,
                               TVRemote + capabilities (PairingCapable, StateReporting), RemoteFactory
    Library/TVLibrary          rules for saved TVs and apps (favorites, renames, recents, ordering, IP moves)
    Control/VolumeStepper      reaches a volume level in single steps
    Persistence/TVRepository   storage interface + UserDefaults implementation
    AndroidTV/  Roku/          protocol drivers (the only platform-specific code)
    Discovery/  Apps/  Updates/
  TCLRemote/                   menu bar app
    App/                       entry point, status item + popover
    State/AppStore             presentation state; coordinates TVKit and system services
    Services/                  connectivity monitor, notifications, login item, preferences
    Presentation/              SwiftUI screens and components
Tests/TVKitTests/              library, repository, stepper, protocol and opt-in live-TV tests
```

- The app talks to TVs only through `TVRemote` and the capability protocols. `RemoteFactory` is the only place that knows the concrete drivers.
- Rules live in `TVLibrary`, a value type with no I/O. `AppStore` applies them and saves through `TVRepository`.
- Adding a TV platform means one new driver in TVKit and one line in `RemoteFactory`.

## Development

```bash
swift test                                              # unit tests
TV_HOST=192.168.1.20 swift test --filter LiveTVTests    # live test against a real Google TV
```

The live test pairs if needed (write the code shown on the TV to the file named by `TV_CODE_FILE`), connects, reads the power and volume state, and presses volume up then down.

`--settings` opens the panel on the Settings screen at launch, which helps when working on Settings.

## Releases

- `scripts/build.sh` builds a universal app. `VERSION=1.2.0` stamps the version; `SIGN_IDENTITY="Developer ID Application: …"` signs it with the hardened runtime (otherwise ad-hoc).
- `scripts/make-dmg.sh` packages `build/TCLRemote-<version>.dmg`. `NOTARY_PROFILE` (from `xcrun notarytool store-credentials`) notarizes and staples it.
- CI ([`ci.yml`](.github/workflows/ci.yml)) runs on every pull request and every push to `main`. It runs the tests, marks each failed test on the PR, writes a results summary, fails if TVKit line coverage drops below the floor (`COVERAGE_MIN`), and builds the app.
- Pushing a tag such as `v1.1.0` runs [`release.yml`](.github/workflows/release.yml), which builds the DMG and publishes a GitHub release. It signs and notarizes when these repository secrets exist: `MACOS_CERT_P12` (base64 Developer ID `.p12`), `MACOS_CERT_PASSWORD`, `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_PASSWORD`.

## Contributing

This project is **open to contributions**: bug reports, ideas, docs and code are all welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md), and please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Changes are listed in [CHANGELOG.md](CHANGELOG.md).

### Help wanted
- **Testing on real TVs:** tell us your TCL model and whether pairing, keys, volume and apps work. It's the most useful contribution there is.
- **Fire TV support:** a new `TVRemote` driver in TVKit plus one line in `RemoteFactory`.
- **More app links** for the Google TV app picker (`AppCatalog`).
- **Tests:** CI fails if TVKit line coverage drops below the floor in [`ci.yml`](.github/workflows/ci.yml), and raising it is welcome.
- **Translations and accessibility** improvements.

Look for issues labelled [`good first issue`](https://github.com/ihusnainalii/tcl-tv-remote/labels/good%20first%20issue) or [`help wanted`](https://github.com/ihusnainalii/tcl-tv-remote/labels/help%20wanted).

## Disclaimer

This is an independent open-source project. It isn't affiliated with, endorsed by or sponsored by TCL, Google, Roku, Amazon, Apple or any app shown in the launcher. All product names, logos and brands are the property of their respective owners and are used only to identify compatible devices and apps. App icons are fetched at runtime from the TV or Apple's public lookup API and aren't distributed with this project.

## License

[Apache License 2.0](LICENSE)
