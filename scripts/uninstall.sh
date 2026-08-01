#!/bin/zsh
set -euo pipefail

application="$HOME/Applications/ClassBell.app"
support="$HOME/Library/Application Support/ClassBell"
cache="$HOME/Library/Caches/ClassBell"

echo "将移除：$application"
if [[ "${1:-}" == "--purge" ]]; then
  echo "同时移除：$support"
  echo "同时移除：$cache"
fi
read "answer?确认卸载？输入 yes："
[[ "$answer" == "yes" ]] || exit 0

osascript -e 'tell application "ClassBell" to quit' 2>/dev/null || true
rm -rf "$application"
if [[ "${1:-}" == "--purge" ]]; then
  rm -rf "$support" "$cache"
fi
echo "ClassBell 已卸载"
