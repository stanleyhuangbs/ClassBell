#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
source_app="$project_root/.dist/ClassBell.app"
target_dir="$HOME/Applications"

if [[ ! -d "$source_app" ]]; then
  "$project_root/scripts/build-app.sh"
fi

mkdir -p "$target_dir"
ditto "$source_app" "$target_dir/ClassBell.app"
open "$target_dir/ClassBell.app"
echo "ClassBell 已安装到 $target_dir/ClassBell.app"
