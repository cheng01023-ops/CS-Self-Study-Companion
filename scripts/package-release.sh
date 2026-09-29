#!/bin/zsh
set -euo pipefail
source "$(dirname "$0")/common.sh"
OUT="$PROJECT_ROOT/build/release"; mkdir -p "$OUT"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
echo "构建完成。正式发布前仍需配置自己的签名。"
