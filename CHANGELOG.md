# Changelog

All notable changes to this project are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
