#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
cd "$project_root"

forbidden='(/Users/[A-Za-z0-9._-]+/|新录音|authorized-reference|Qwen3-TTS|AppSecret|access_token|BEGIN (RSA|OPENSSH) PRIVATE KEY)'
if rg -n --hidden \
  --glob '!.git/**' --glob '!.build/**' --glob '!.dist/**' \
  --glob '!scripts/audit-public.sh' "$forbidden" .; then
  echo "公开审计失败：发现私人路径、素材标记或密钥特征"
  exit 1
fi

if find . -type f \
  -not -path './.git/*' -not -path './.build/*' -not -path './.dist/*' \
  -size +5M -print | grep -q .; then
  echo "公开审计失败：发现超过 5MB 的源码文件"
  exit 1
fi

echo "公开审计通过"
