#!/usr/bin/env bash
#
# archive-progress.sh — 把 .ai/progress.md 的旧段落归档到 .ai/archive/<YYYY-MM>.md
#
# 用法：
#   bash scripts/archive-progress.sh                # 默认保留最近 30 天
#   bash scripts/archive-progress.sh --keep-days 7  # 自定义阈值
#   bash scripts/archive-progress.sh --dry-run      # 只看会动哪些段落，不写文件
#
# 工作方式：
#   - 按 "## YYYY-MM-DD" 切段
#   - 早于阈值的段按 YYYY-MM 分组写入 .ai/archive/<key>.md（追加）
#   - 仍在阈值内的段保留在 progress.md
#   - 文件开头的 preamble（首个 ## 之前的内容）始终保留

set -euo pipefail

KEEP_DAYS=30
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-days)
      KEEP_DAYS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      sed -n '3,11p' "$0"
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      exit 1
      ;;
  esac
done

DEVOPS_ROOT="${DEVICEOPS_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PROGRESS="$DEVOPS_ROOT/.ai/progress.md"
ARCHIVE_DIR="$DEVOPS_ROOT/.ai/archive"

if [[ ! -f "$PROGRESS" ]]; then
  echo "找不到 $PROGRESS" >&2
  exit 1
fi

mkdir -p "$ARCHIVE_DIR"

python3 - "$PROGRESS" "$ARCHIVE_DIR" "$KEEP_DAYS" "$DRY_RUN" <<'PY'
import re
import sys
from datetime import datetime, timedelta
from pathlib import Path

progress_path = Path(sys.argv[1])
archive_dir = Path(sys.argv[2])
keep_days = int(sys.argv[3])
dry_run = sys.argv[4] == "1"

text = progress_path.read_text(encoding="utf-8")

# 按 ## YYYY-MM-DD 起始的行切段
parts = re.split(r"(?m)^(?=## \d{4}-\d{2}-\d{2})", text)

if not parts:
    print("文件为空，无事可做")
    sys.exit(0)

preamble = parts[0] if not parts[0].startswith("## ") else ""
sections = parts[1:] if preamble else parts

cutoff = datetime.now() - timedelta(days=keep_days)
kept = []
archive_buckets = {}  # YYYY-MM -> [section, ...]

for s in sections:
    m = re.match(r"## (\d{4})-(\d{2})-(\d{2})", s)
    if not m:
        kept.append(s)
        continue
    y, mo, d = int(m.group(1)), int(m.group(2)), int(m.group(3))
    try:
        dt = datetime(y, mo, d)
    except ValueError:
        kept.append(s)
        continue
    if dt < cutoff:
        key = f"{y:04d}-{mo:02d}"
        archive_buckets.setdefault(key, []).append(s)
    else:
        kept.append(s)

print(f"[scan] 共 {len(sections)} 段；保留 {len(kept)} 段；归档 {sum(len(v) for v in archive_buckets.values())} 段")

if not archive_buckets:
    print("[done] 无需归档")
    sys.exit(0)

for key, secs in sorted(archive_buckets.items()):
    target = archive_dir / f"{key}.md"
    header = f"# Progress Archive: {key}\n\n"
    existing = target.read_text(encoding="utf-8") if target.exists() else header
    new_content = existing + "".join(secs)
    print(f"[archive] {key}: {len(secs)} 段 -> {target}")
    if not dry_run:
        target.write_text(new_content, encoding="utf-8")

if not dry_run:
    progress_path.write_text(preamble + "".join(kept), encoding="utf-8")
    print(f"[rewrite] {progress_path} 现保留 {len(kept)} 段")
else:
    print("[dry-run] 未写任何文件")
PY
