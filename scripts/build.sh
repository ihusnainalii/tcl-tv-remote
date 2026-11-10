#!/bin/bash
# Builds a universal (Apple Silicon + Intel) "build/TCL Remote.app".
#   VERSION=1.2.0        version to stamp into Info.plist (default: from Info.plist)
#   SIGN_IDENTITY="Developer ID Application: Name (TEAMID)"   real signing; default ad-hoc
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/TCLRemote"  # path differs between toolchains

APP="build/TCL Remote.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
# SwiftPM resource bundle (Localizable.strings for SwiftGen's L10n); the app can't start without it.
cp -R "$(dirname "$BIN")/TCLRemote_RemoteUI.bundle" "$APP/Contents/Resources/"
if [[ -n "${VERSION:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION#v}" "$APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER:-1}" "$APP/Contents/Info.plist"
fi

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  # Hardened runtime + secure timestamp are required for notarization.
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
else
  codesign --force --sign - "$APP"
fi
codesign --verify --strict "$APP"
lipo -archs "$APP/Contents/MacOS/TCLRemote"
echo "Built $APP"
