#!/bin/zsh
set -euo pipefail
source "$(dirname "$0")/common.sh"
DEVICE_ID="$(find_physical_iphone)"
[[ -n "$DEVICE_ID" ]] || { echo "没有找到已配对的 iPhone。"; exit 1; }
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -destination "id=$DEVICE_ID" -allowProvisioningUpdates -allowProvisioningDeviceRegistration build
TARGET_BUILD_DIR=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -destination "id=$DEVICE_ID" -showBuildSettings 2>/dev/null | awk -F ' = ' '/TARGET_BUILD_DIR = / {print $2; exit}')
BUNDLE_ID=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -destination "id=$DEVICE_ID" -showBuildSettings 2>/dev/null | awk -F ' = ' '/PRODUCT_BUNDLE_IDENTIFIER = / {print $2; exit}')
xcrun devicectl device install app --device "$DEVICE_ID" "$TARGET_BUILD_DIR/CS 自学.app"
xcrun devicectl device process launch --terminate-existing --device "$DEVICE_ID" "$BUNDLE_ID"
