#!/bin/zsh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT="$PROJECT_ROOT/CSSelfStudyCompanion.xcodeproj"
SCHEME="CSSelfStudyCompanion"
find_physical_iphone() {
  xcrun devicectl list devices --json-output - 2>/dev/null | python3 -c '
import json, sys
data=json.load(sys.stdin)
for device in data.get("result",{}).get("devices",[]):
    hw=device.get("properties",{}).get("hardware",{})
    conn=device.get("properties",{}).get("connection",{})
    if hw.get("reality")=="physical" and conn.get("pairingState")=="paired" and hw.get("udid"):
        print(hw["udid"])
        break
'
}
