#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
distribution_dir="$project_root/.dist"
application="$distribution_dir/ClassBell.app"
module_cache="$project_root/.build/module-cache"

mkdir -p "$module_cache"
export CLANG_MODULE_CACHE_PATH="$module_cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$module_cache"

cd "$project_root"
swift build --disable-sandbox -c release --triple arm64-apple-macosx13.0
swift build --disable-sandbox -c release --triple x86_64-apple-macosx13.0

mkdir -p "$application/Contents/MacOS" "$application/Contents/Resources"
lipo -create \
  "$project_root/.build/arm64-apple-macosx/release/ClassBell" \
  "$project_root/.build/x86_64-apple-macosx/release/ClassBell" \
  -output "$application/Contents/MacOS/ClassBell"
install -m 644 "$project_root/Resources/Info.plist" "$application/Contents/Info.plist"
codesign --force --deep --sign - "$application"

rm -f "$distribution_dir/ClassBell-1.0.0-macOS.zip"
ditto -c -k --sequesterRsrc --keepParent \
  "$application" "$distribution_dir/ClassBell-1.0.0-macOS.zip"

file "$application/Contents/MacOS/ClassBell"
codesign --verify --deep --strict "$application"
echo "$distribution_dir/ClassBell-1.0.0-macOS.zip"
