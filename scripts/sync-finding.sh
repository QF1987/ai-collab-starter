#!/usr/bin/env bash
#
# sync-finding.sh — Copy a finding from project's local .ai/logs/ to starter inbox
#
# 用法:
#   bash <path-to>/ai-collab-starter/scripts/sync-finding.sh <local-finding-path>
#
# 示例:
#   cd DeviceOps
#   # 写完 .ai/logs/starter-v3-finding-23-X.md 后:
#   bash /path/to/ai-collab-starter/scripts/sync-finding.sh \
#        .ai/logs/starter-v3-finding-23-X.md
#
# 自动:
#   - 检测 project name(读 git remote 或 pwd basename)
#   - 在 starter/.ai/logs/pending-findings/from-<project>/ 创建子目录
#   - cp finding 文件到 inbox
#
# 退出码:
#   0 — 同步成功
#   1 — 调用错误 / starter 找不到 / finding 文件不存在

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "用法: sync-finding.sh <local-finding-path>" >&2
  exit 1
fi

LOCAL_FINDING="$1"

if [[ ! -f "$LOCAL_FINDING" ]]; then
  echo "ERROR: finding 文件不存在: $LOCAL_FINDING" >&2
  exit 1
fi

# 找 starter
STARTER="${AI_COLLAB_STARTER:-}"
if [[ -z "$STARTER" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  STARTER="$(dirname "$SCRIPT_DIR")"
fi

if [[ ! -d "$STARTER/.ai/logs/pending-findings" ]]; then
  echo "ERROR: starter inbox 不存在: $STARTER/.ai/logs/pending-findings/" >&2
  exit 1
fi

# 推断 project name:优先 git remote URL 末段,否则 pwd basename
PROJECT_NAME=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || true)
  if [[ -n "$REMOTE_URL" ]]; then
    PROJECT_NAME=$(basename "$REMOTE_URL" .git)
  fi
fi
if [[ -z "$PROJECT_NAME" ]]; then
  PROJECT_NAME=$(basename "$(pwd)")
fi

# 目标目录
DEST_DIR="$STARTER/.ai/logs/pending-findings/from-$PROJECT_NAME"
mkdir -p "$DEST_DIR"

# 检查目标是否已存在(避免覆盖)
BASENAME=$(basename "$LOCAL_FINDING")
if [[ -f "$DEST_DIR/$BASENAME" ]]; then
  echo "WARN: $DEST_DIR/$BASENAME 已存在,跳过(若要覆盖请手动 cp -f)" >&2
  exit 0
fi

cp "$LOCAL_FINDING" "$DEST_DIR/"
echo "✓ Synced: $LOCAL_FINDING → $DEST_DIR/$BASENAME"

# 提醒触发阈值
PENDING_COUNT=$(find "$STARTER/.ai/logs/pending-findings" -type f -name 'starter-v*-finding-*.md' 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "Starter inbox now: $PENDING_COUNT pending finding(s)"
if [[ "$PENDING_COUNT" -ge 5 ]]; then
  echo "🟡 达到升级阈值(≥5)。建议启动 starter 升级 session(参考 .ai/starter-upgrade-protocol.md)。"
fi
