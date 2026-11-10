#!/bin/bash
# Builds "build/TCL Remote.app" (menu bar app, ad-hoc signed).
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
APP="build/TCL Remote.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/TCLRemote "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"
echo "Built $APP"
