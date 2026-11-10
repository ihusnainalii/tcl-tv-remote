# TCL Remote for Mac

A menu bar remote for TCL TVs. It finds TVs on your network, remembers them, and reconnects on its own.

- **Google TV / Android TV TCLs**: Android TV Remote v2 protocol (TLS, one-time on-screen code pairing)
- **Roku TV TCLs**: Roku ECP (HTTP :8060, no pairing)

## Features
- Network discovery (Bonjour `_androidtvremote2._tcp` + SSDP `roku:ecp`), or add a TV by IP
- Remembers TVs with "last used", auto-connects to the last one on launch and whenever the Mac rejoins a network, and follows the TV to a new IP if DHCP moves it, retries every 10 s while offline and reconnects after sleep
- Power (toggle, on, off), guide, exit, captions, stop/next/previous, D-pad/OK, back, home, menu/settings, info, search, volume, mute, channels, media keys, HDMI 1–4 / AV / Live TV input, live volume level (Google TV), number pad
- Type text on the TV, launch apps (Roku lists installed apps; Google TV has common shortcuts)
- Hold arrows, volume or channel buttons to repeat
- Favorite and rename TVs (favorite auto-connects first); favorite, recent and custom app shortcuts with search
- macOS notifications when a TV disconnects, reconnects or needs pairing
- Settings window (⋯ → Settings…, or ⌘,): launch at login, auto-connect, retry interval, notifications, saved TVs, reset pairing
- Keyboard: arrows, Return = OK, Delete = Backspace, Esc = Back, Space = Play/Pause, `+`/`-` volume, `m` mute, `h` home

## Build & run
```bash
./scripts/build.sh
open "build/TCL Remote.app"   # or scripts/make-dmg.sh for an installer
```
Requires macOS 15+ and Xcode. Allow **Local Network** access when macOS asks.

## Architecture
```
Sources/
  TVKit/                     core library: no UI, unit-tested
    Domain/                  TV, KnownTV, TVApp, Key, TVError, TVRemote protocol, SavedTVs
    AndroidTV/               Remote v2: protobuf, TLS connection, pairing crypto, remote
    Roku/                    ECP remote
    Discovery/               Bonjour + SSDP
    Updates/                 GitHub release check
  TCLRemote/                 menu bar app
    App/                     @main scene
    State/                   AppStore: connection lifecycle, saved TVs, notifications
    Presentation/            SwiftUI screens and components
Tests/TVKitTests/
```
The app depends on `TVKit` through its public API only; adding a TV platform means one new `TVRemote` implementation in TVKit.

## Distribution
- `scripts/build.sh` builds a universal (Apple Silicon + Intel) app. Set `VERSION=1.2.0` to stamp the version and `SIGN_IDENTITY="Developer ID Application: …"` to sign with hardened runtime (ad-hoc otherwise).
- `scripts/make-dmg.sh` packages `build/TCLRemote-<version>.dmg`. Set `NOTARY_PROFILE` (from `xcrun notarytool store-credentials`) to notarize and staple.
- CI (`.github/workflows/ci.yml`) runs tests with coverage and builds the app on every PR and push to `main`.
- Releases (`.github/workflows/release.yml`): push a tag like `v1.1.0` and GitHub builds the DMG and publishes a release. Signing and notarization run when these repo secrets exist: `MACOS_CERT_P12` (base64 Developer ID .p12), `MACOS_CERT_PASSWORD`, `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_PASSWORD`.
- Settings → About → **Check for Updates** compares against the latest GitHub release (works once the repo is public).

## Notes
- The Google TV pairing certificate is stored in the macOS Keychain (item "TCL Remote pairing certificate"). Delete it to re-pair from scratch.
- Roku: if keys don't work, set *Settings → System → Advanced system settings → Control by mobile apps* to **Default** or **Permissive**.
- Launch at login: ⋯ menu in the panel header. Honors Reduce Motion and has VoiceOver labels.
