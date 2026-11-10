# TCL Remote for Mac

A menu bar remote for TCL TVs. It finds TVs on your network, remembers them, and reconnects on its own.

- **Google TV / Android TV TCLs**: Android TV Remote v2 protocol (TLS, one-time on-screen code pairing)
- **Roku TV TCLs**: Roku ECP (HTTP :8060, no pairing)

## Features
- Network discovery (Bonjour `_androidtvremote2._tcp` + SSDP `roku:ecp`), or add a TV by IP
- Remembers TVs with "last used", auto-connects to the last one on launch and whenever the Mac rejoins a network, and follows the TV to a new IP if DHCP moves it
- Power, D-pad/OK, back, home, menu/settings, info, search, volume, mute, channels, media keys, HDMI 1–4 / tuner input, number pad
- Type text on the TV, launch apps (Roku lists installed apps; Google TV has common shortcuts)
- Keyboard: arrows, Return = OK, Delete = Back, Space = Play/Pause, `+`/`-` volume, `m` mute, `h` home

## Build & run
```bash
./build.sh
open "build/TCL Remote.app"
```
Requires macOS 15+ and Xcode. Allow **Local Network** access when macOS asks.

## Notes
- The client certificate for Google TV pairing lives in `~/Library/Application Support/TCLRemote/`. Delete it to re-pair from scratch.
- Roku: if keys don't work, set *Settings → System → Advanced system settings → Control by mobile apps* to **Default** or **Permissive**.
