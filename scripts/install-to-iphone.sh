#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
IPA="$ROOT/CS 自学-iOS-开发者签名.ipa"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -f "$IPA" ]]; then
  echo "找不到 IPA：$IPA"
  exit 1
fi

echo "正在查找已配对的 iPhone..."
DEVICE_ID=$(xcrun devicectl list devices --json-output - 2>/dev/null | python3 -c '
import json, sys
data = json.load(sys.stdin)
for device in data.get("result", {}).get("devices", []):
    hardware = device.get("properties", {}).get("hardware", {})
    connection = device.get("properties", {}).get("connection", {})
    if hardware.get("platform") == "iOS" and hardware.get("reality") != "simulated":
        if connection.get("pairingState") == "paired":
            print(device.get("identifier", ""))
            break
')

if [[ -z "$DEVICE_ID" ]]; then
  echo "没有找到已配对的 iPhone。"
  echo "请先在 iPhone 上完成："
  echo "1. 设置 → 隐私与安全性 → 开发者模式 → 打开并重启"
  echo "2. 使用数据线连接 Mac，解锁 iPhone"
  echo "3. 在 iPhone 上点击“信任此电脑”并输入锁屏密码"
  echo "4. 重新运行本脚本"
  exit 1
fi

echo "正在解压应用..."
ditto -x -k "$IPA" "$TMP_DIR"

echo "正在安装到 iPhone..."
xcrun devicectl device install app --device "$DEVICE_ID" "$TMP_DIR/Payload/CS 自学.app"
echo "安装完成。"
