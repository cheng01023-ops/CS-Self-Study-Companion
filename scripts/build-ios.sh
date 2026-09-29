#!/bin/zsh
set -euo pipefail
source "$(dirname "$0")/common.sh"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
