#!/bin/zsh
set -euo pipefail
source "$(dirname "$0")/common.sh"
xcodebuild -project "$PROJECT" -scheme CSSelfStudyCompanion-MacTests -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test
