#!/bin/zsh
set -euo pipefail
source "$(dirname "$0")/common.sh"
LOG_DIR="$PROJECT_ROOT/build/test-results-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOG_DIR"
xcodebuild -project "$PROJECT" -scheme CSSelfStudyCompanion-MacTests -destination 'platform=macOS' -enableCodeCoverage YES CODE_SIGNING_ALLOWED=NO test | tee "$LOG_DIR/macos.log"
SIMULATOR_ID=$(xcrun simctl list devices available --json | python3 -c '
import json,sys
data=json.load(sys.stdin); items=[]
for runtime, devices in data.get("devices",{}).items():
    if "iOS" not in runtime: continue
    for d in devices:
        if d.get("isAvailable") and "iPhone" in d.get("name",""):
            items.append((0 if "iPhone 17 Pro" in d["name"] else 1,d["name"],d["udid"]))
items.sort(); print(items[0][2] if items else "")
')
xcodebuild -project "$PROJECT" -scheme CSSelfStudyCompanion-iOSTests -destination "platform=iOS Simulator,id=$SIMULATOR_ID" -enableCodeCoverage YES test | tee "$LOG_DIR/ios.log"
