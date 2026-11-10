# Changelog

All notable changes to this project are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Apple Watch companion app (arrow pad, Digital Crown volume, controls, apps) relaying through the iPhone; direct Roku control from the watch.
- iPhone and iPad Home Screen widget (small and medium) with one-tap remote buttons.
- Stops automatic retries and scans after 5 failed attempts in a row; the banner says so and Retry still works. A network change or wake allows one more attempt.
- Clear, actionable error messages everywhere, with the reason shown in the offline banner; details logged for debugging.
- First-launch walkthrough on iPhone and iPad; launch screen and a new TV app icon (Mac and iOS). iPad shows only Remote and Settings tabs. Mobile remote uses one consistent gap between rows.
- Native iPhone and iPad design: tab bar (Remote, Apps, Keys, Settings), touchpad mode with haptics, TV switcher, pairing sheet, two-column iPad remote. The Mac menu bar panel is unchanged.
- Fixed: the Pair button was disabled while a TV needed pairing (Mac and iOS).
- Keyboard shortcuts in Settings only show when a hardware keyboard is connected (iOS).
- iPhone and iPad app sharing all screens and logic with the Mac app (new `RemoteUI` module; `iOS/` XcodeGen project). Native X.509 certificate generation for pairing on iOS. CI builds the iOS app.
- Fixed the power button's glow being clipped at the panel edge.
- SwiftLint (strict) and SwiftGen. All UI text moved to `Localizable.strings` with a generated `L10n` API, ready for translations. CI gains a Lint stage.

## [1.1.0] - 2026-11-10

### Added
- Menu bar remote for TCL Google TV, Android TV and Roku TV, with discovery via Bonjour and SSDP, or adding a TV by IP address.
- One-time code pairing for Google TV (Android TV Remote v2), with the certificate stored in the Keychain.
- Saved TVs with last-used times, favorites and renaming; auto-connect; reconnecting after network changes, sleep or TV restarts; following a TV whose IP address changes.
- Full remote: arrow pad, power on/off, volume and channel buttons with hold-to-repeat, media keys, HDMI 1–4, AV and Live TV inputs, number keypad, guide, captions and more.
- Live volume bar on Google TV that you can drag or swipe on the trackpad.
- Type tab: a live keyboard for the TV's search and text boxes.
- App launcher with real icons, favorites, recent apps and search; a picker of popular TV apps for Google TV, plus custom links.
- Settings inside the panel; color themes, a custom color and Light/Dark mode; launch at login; notifications.
- Universal build script, DMG packaging, CI and tagged release workflows, and Check for Updates.
- Clean two-module architecture (TVKit core and app) with unit tests and an opt-in live-TV test.
- Test suite with a fake Google TV, stubbed HTTP, local discovery responders and a test-only Keychain item; CI requires 90% TVKit coverage and no failing tests, and marks failed tests on pull requests.
- App icon, README screenshots and launch options for opening the panel at launch.
