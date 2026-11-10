# Security Policy

## Supported versions

Only the latest release gets security fixes.

## Reporting a vulnerability

Please **don't open a public issue** for security problems.

Report it privately through GitHub instead: **Security → Report a vulnerability** on this repository. Include:

- what the problem is and what an attacker could do with it
- steps to reproduce it
- the app version, macOS version and TV model, if relevant

You can expect an acknowledgement within a few days and updates as it's investigated. Credit is given in the release notes unless you'd rather stay anonymous.

## Scope and known limitations

- The app only talks to devices on your local network. Roku's control protocol is unencrypted HTTP by design. Google TV traffic uses TLS.
- The app accepts the TV's self-signed certificate without pinning it, as TV remote apps generally do. Someone already on your local network could therefore impersonate a TV. Reports that improve on this are welcome.
- The Google TV pairing certificate is stored in the macOS Keychain.
