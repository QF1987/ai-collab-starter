#!/usr/bin/env bash
#
# init-collab.sh — Bootstrap a new project with the AI collaboration framework.
#
# 把 starter kit 骨架（.ai/、AGENTS.md、scripts/、.claude/）复制到目标项目目录。
# 复制完成后，运行 .ai/getting-started.md §1 Step 4 描述的 Claude bootstrap session
# 让 Claude 填充项目特定内容（context.md / architecture.md / AGENTS.md）。
#
# 用法：
#   $0 --target <path> --name <project-name> [--force]
#
# 选项：
#   --target  目标项目目录绝对路径（必填）
#   --name    项目名，用于替换 AGENTS.md 中 <PROJECT_NAME> 占位符（必填）
#   --force   目标已有 .ai/ 时强制覆盖（默认拒绝，避免误操作）
#   --help    显示帮助
#
# 退出码：
#   0 成功
#   1 参数错误
#   2 目标已有 .ai/ 且未指定 --force
#   3 starter kit 自身缺失关键文件

set -euo pipefail

# ===== 解析参数 =====

TARGET=""
NAME=""
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --name)
      NAME="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --help|-h)
      cat << 'EOF'
init-collab.sh — Bootstrap a new project with the AI collaboration framework.

把 starter kit 骨架（.ai/、AGENTS.md、scripts/、.claude/）复制到目标项目目录。
复制完成后，运行 .ai/getting-started.md §1 Step 4 描述的 Claude bootstrap session
让 Claude 填充项目特定内容（context.md / architecture.md / AGENTS.md）。

用法：
  init-collab.sh --target <path> --name <project-name> [--force]

选项：
  --target  目标项目目录绝对路径（必填）
  --name    项目名，用于替换 AGENTS.md 中 <PROJECT_NAME> 占位符（必填）
  --force   目标已有 .ai/ 时强制覆盖（默认拒绝，避免误操作）
  --help    显示本帮助

退出码：
  0 成功
  1 参数错误
  2 目标已有 .ai/ 且未指定 --force
  3 starter kit 自身缺失关键文件
EOF
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      echo "Usage: $0 --target <path> --name <project-name> [--force]" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "ERROR: --target <path> required" >&2
  exit 1
fi

if [[ -z "$NAME" ]]; then
  echo "ERROR: --name <project-name> required" >&2
  exit 1
fi

# ===== 定位 starter kit 自身路径 =====

STARTER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Sanity check：starter kit 完整性
for required in "$STARTER_ROOT/.ai/prompts" "$STARTER_ROOT/AGENTS.md" "$STARTER_ROOT/.claude/skills/intake/SKILL.md"; do
  if [[ ! -e "$required" ]]; then
    echo "ERROR: Starter kit missing required path: $required" >&2
    echo "       Is this script being run from a complete starter kit?" >&2
    exit 3
  fi
done

# ===== 目标目录检查 =====

if [[ -e "$TARGET/.ai" ]]; then
  if [[ $FORCE -eq 0 ]]; then
    echo "ERROR: $TARGET/.ai already exists. Use --force to overwrite." >&2
    exit 2
  else
    echo "WARNING: Overwriting existing $TARGET/.ai (--force given)"
  fi
fi

mkdir -p "$TARGET"

# ===== 复制骨架 =====

echo "📂 Copying skeleton from $STARTER_ROOT to $TARGET ..."

cp -r "$STARTER_ROOT/.ai"        "$TARGET/"
cp    "$STARTER_ROOT/AGENTS.md"  "$TARGET/"
cp -r "$STARTER_ROOT/scripts"    "$TARGET/"
cp -r "$STARTER_ROOT/.claude"    "$TARGET/"

# 子项目不再需要 init-collab.sh 自身
rm -f "$TARGET/scripts/init-collab.sh"

# ===== 替换 AGENTS.md 中的 <PROJECT_NAME> 占位符 =====

if [[ -f "$TARGET/AGENTS.md" ]]; then
  # 兼容 BSD sed (macOS) 与 GNU sed
  if sed --version >/dev/null 2>&1; then
    # GNU sed
    sed -i "s/<PROJECT_NAME>/$NAME/g" "$TARGET/AGENTS.md"
  else
    # BSD sed
    sed -i '' "s/<PROJECT_NAME>/$NAME/g" "$TARGET/AGENTS.md"
  fi
  echo "✏️  Replaced <PROJECT_NAME> → $NAME in AGENTS.md"
fi

# ===== 完成 =====

cat << EOF

✅ Skeleton copied to: $TARGET

📋 Next steps:

  1. cd $TARGET
  2. Read .ai/getting-started.md §1 (5-step bootstrap procedure)
  3. Write your first ADR in .ai/decisions.md (Step 3 of getting-started.md)
  4. Run Claude bootstrap session (Step 4):
     - Open Claude Code in $TARGET
     - Paste the bootstrap prompt from getting-started.md §1 Step 4
     - Claude will populate:
       - .ai/context.md (from context.md.template)
       - .ai/architecture.md (from architecture.md.template)
       - AGENTS.md (fill in Tech Stack / Build Commands / Known Sharp Edges)
  5. Human review (Step 5): rename .ai/*.template → .ai/*.md after filling in

🔎 Verify skeleton:

  ls -la $TARGET/.ai/         # prompts/, workflow.md, getting-started.md, etc.
  ls -la $TARGET/.ai/prompts/ # 01-08-*.md (8 prompt templates)
  ls -la $TARGET/.claude/skills/intake/   # SKILL.md

💡 Tip: Tiny tasks (< 30 lines) should NOT use this framework.
   See .ai/getting-started.md §4 "什么情况都别套这个框架".

EOF
