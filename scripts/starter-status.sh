#!/usr/bin/env bash
#
# starter-status.sh — Report starter version + drift + pending findings
#
# 用法:
#   bash <path-to>/ai-collab-starter/scripts/starter-status.sh
#   或者(在 derived 项目内,只要 init-collab.sh 复制了本脚本):
#   bash scripts/starter-status.sh
#
# 输出:
#   - 当前 starter 版本(读 ai-collab-starter/VERSION)
#   - 调用方项目的 STARTER_VERSION stamp(若存在)+ drift 检测
#   - pending findings 数 + 分桶
#   - 触发阈值检查(是否建议升级)
#
# 退出码:
#   0 — 状态正常
#   1 — 调用错误(找不到 starter)
#   2 — 检测到严重 drift(警告但不阻塞)

set -euo pipefail

# 找 starter 路径:优先环境变量,然后常见位置
STARTER="${AI_COLLAB_STARTER:-}"
if [[ -z "$STARTER" ]]; then
  # 猜:从本脚本所在目录的父目录
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  CANDIDATE="$(dirname "$SCRIPT_DIR")"
  if [[ -f "$CANDIDATE/VERSION" && -d "$CANDIDATE/.ai/logs/pending-findings" ]]; then
    STARTER="$CANDIDATE"
  else
    # 猜:在调用方仓库的同级
    PWD_PARENT="$(dirname "$(pwd)")"
    if [[ -d "$PWD_PARENT/ai-collab-starter" ]]; then
      STARTER="$PWD_PARENT/ai-collab-starter"
    fi
  fi
fi

if [[ -z "$STARTER" || ! -f "$STARTER/VERSION" ]]; then
  echo "ERROR: 找不到 ai-collab-starter 仓库。请设环境变量 AI_COLLAB_STARTER=<path>。" >&2
  exit 1
fi

STARTER_VERSION="$(cat "$STARTER/VERSION" | tr -d '[:space:]')"

# 读调用方项目的 stamp(如果有)
PROJECT_DIR="$(pwd)"
PROJECT_STAMP=""
if [[ -f "$PROJECT_DIR/.ai/STARTER_VERSION" ]]; then
  PROJECT_STAMP="$(cat "$PROJECT_DIR/.ai/STARTER_VERSION" | head -n1 | awk '{print $1}' | tr -d '[:space:]')"
fi

# 统计 pending findings
PENDING_DIR="$STARTER/.ai/logs/pending-findings"
PENDING_COUNT=0
if [[ -d "$PENDING_DIR" ]]; then
  PENDING_COUNT=$(find "$PENDING_DIR" -type f -name 'starter-v*-finding-*.md' 2>/dev/null | wc -l | tr -d ' ')
fi

# 分桶统计(按来源项目)
echo "===================================================="
echo "  AI Collab Starter · Status Report"
echo "===================================================="
echo ""
echo "Starter latest VERSION:  $STARTER_VERSION"
if [[ -n "$PROJECT_STAMP" ]]; then
  echo "Project STARTER_VERSION: $PROJECT_STAMP"
  if [[ "$PROJECT_STAMP" != "$STARTER_VERSION" ]]; then
    echo "  ⚠️  Drift detected: project lagging behind starter"
    echo "      Run: rsync the starter .ai/ to project (manual or via sync helper)"
  else
    echo "  ✓ project synced with latest starter"
  fi
else
  echo "Project STARTER_VERSION: (not stamped — likely not a derived project)"
fi

echo ""
echo "Pending findings in inbox: $PENDING_COUNT"
if [[ "$PENDING_COUNT" -gt 0 ]]; then
  for project_dir in "$PENDING_DIR"/*/; do
    if [[ -d "$project_dir" ]]; then
      proj=$(basename "$project_dir")
      n=$(find "$project_dir" -type f -name 'starter-v*-finding-*.md' 2>/dev/null | wc -l | tr -d ' ')
      echo "  ├─ $proj: $n"
    fi
  done
fi

echo ""
# 触发阈值
echo "升级触发评估:"
if [[ "$PENDING_COUNT" -ge 5 ]]; then
  echo "  🟡 累计 pending finding ≥ 5,建议启动 starter 升级 session"
  echo "     运行 starter-upgrade-protocol.md 7-step 仪式"
elif [[ "$PENDING_COUNT" -ge 1 ]]; then
  echo "  🟢 累计 pending finding $PENDING_COUNT 条,未达升级阈值(>= 5)"
  echo "     可继续累积或在 epic-closeout 时回顾"
else
  echo "  ✓ 无 pending finding"
fi

# P0/P1 严重 finding 探测(扫 file frontmatter)
P01_COUNT=$(find "$PENDING_DIR" -type f -name 'starter-v*-finding-*.md' -exec grep -l 'severity: P[01]\|severity:.*P[01]\b' {} \; 2>/dev/null | wc -l | tr -d ' ')
if [[ "$P01_COUNT" -gt 0 ]]; then
  echo "  🔴 检测到 $P01_COUNT 条 P0/P1 finding 未实施,**强烈建议立即升级**"
fi

echo ""
echo "===================================================="
echo "  Files:"
echo "    Starter version: $STARTER/VERSION"
echo "    Inbox:           $PENDING_DIR/"
echo "    Archive:         $STARTER/.ai/logs/archived/"
echo "===================================================="
