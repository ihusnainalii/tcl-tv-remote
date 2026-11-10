#!/bin/bash
# Packages build/TCL Remote.app into build/TCLRemote-<version>.dmg.
#   NOTARY_PROFILE=name   notarize with a stored `xcrun notarytool store-credentials` profile
#   APPLE_ID / APPLE_TEAM_ID / APPLE_APP_PASSWORD   or notarize with these (CI)
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/TCL Remote.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
DMG="build/TCLRemote-$VERSION.dmg"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "TCL Remote" -srcfolder "$STAGE" -fs HFS+ -format UDZO -quiet "$DMG"
[[ -n "${SIGN_IDENTITY:-}" ]] && codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
elif [[ -n "${APPLE_ID:-}" ]]; then
  xcrun notarytool submit "$DMG" --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD" --wait
  xcrun stapler staple "$DMG"
fi
echo "Built $DMG"
