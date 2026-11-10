#!/bin/bash
# Captures README screenshots of the menu bar panel into docs/screenshots/.
# Needs a built app (scripts/build.sh) and, for the remote shots, a reachable TV.
# Your own panel settings are saved first and restored afterwards.
set -euo pipefail
cd "$(dirname "$0")/.."
APP="build/TCL Remote.app"
DOMAIN=app.tclremote.mac
OUT=docs/screenshots
mkdir -p "$OUT"
KEYS=(remoteTab settingsTab accentStyle appearanceMode)

saved=()
for k in "${KEYS[@]}"; do saved+=("$(defaults read $DOMAIN "$k" 2>/dev/null || echo __unset__)"); done
restore() {
  for i in "${!KEYS[@]}"; do
    if [[ "${saved[$i]}" == __unset__ ]]; then defaults delete $DOMAIN "${KEYS[$i]}" 2>/dev/null || true
    else defaults write $DOMAIN "${KEYS[$i]}" "${saved[$i]}"; fi
  done
  pkill -f "$APP/Contents/MacOS" || true
}
trap restore EXIT

window_id() { # the panel: tallest window owned by the app's process
  local pid; pid=$(pgrep -f "$APP/Contents/MacOS" | head -1)
  swift -e "import CoreGraphics
let l = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as! [[String: Any]]
let mine = l.filter { (\$0[\"kCGWindowOwnerPID\"] as? Int) == $pid }
let best = mine.max { ((\$0[\"kCGWindowBounds\"] as? [String: Any])?[\"Height\"] as? Double ?? 0) < ((\$1[\"kCGWindowBounds\"] as? [String: Any])?[\"Height\"] as? Double ?? 0) }
print(best?[\"kCGWindowNumber\"] ?? \"\")"
}

shot() { # name, launch flag, then key=value defaults
  local name=$1 flag=$2; shift 2
  pkill -f "$APP/Contents/MacOS" || true; sleep 1
  for kv in "$@"; do defaults write $DOMAIN "${kv%%=*}" "${kv#*=}"; done
  open "$APP" --args "$flag"
  sleep "${WAIT:-7}"
  local id; id=$(window_id)
  [[ -n "$id" ]] || { echo "no window for $name"; return 1; }
  screencapture -o -x -l"$id" "$OUT/$name.png"
  echo "captured $OUT/$name.png"
}

shot remote       --open     remoteTab=Apps     accentStyle=violet appearanceMode=dark
shot remote-more  --open     remoteTab=More     accentStyle=violet appearanceMode=dark
shot light-ocean  --open     remoteTab=Keypad   accentStyle=ocean  appearanceMode=light
shot settings     --settings settingsTab=General accentStyle=violet appearanceMode=dark
shot themes       --settings settingsTab=Look   accentStyle=sunset appearanceMode=dark
