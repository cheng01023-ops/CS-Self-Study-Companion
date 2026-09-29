#!/bin/zsh
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$PROJECT_ROOT"
if ! git remote get-url origin >/dev/null 2>&1; then
  read "REMOTE_URL?请输入 GitHub 仓库地址："
  git remote add origin "$REMOTE_URL"
fi
git add -A
if ! git diff --cached --quiet; then
  read "MESSAGE?请输入提交说明："
  git commit -m "${MESSAGE:-更新 CS 自学}"
fi
git push -u origin main
