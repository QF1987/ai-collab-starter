---
finding-id: starter-v5.2-finding-29-archive-progress-script-default-root
severity: P3
category: scripts(运维脚本默认值)
source-project: DeviceOps
discovered: 2026-05-26
target:
  - scripts/archive-progress.sh(默认 root 改用 $PWD 而非 $(dirname "$0")/..)
status: pending
related: [27]
---

# Finding 29: archive-progress.sh 默认 root 指向 starter 自己,而非调用方项目

## 现象

DeviceOps M3-Beta-Scale epic intake 完成后,Human 按 AGENTS.md v5.2.0-rc2 progress.md 行数自检建议
(progress.md 1636 行,≥ 500 建议档)从 DeviceOps 目录跑:

```bash
cd /Users/qf/Alcedo/code/DeviceOps
bash /Users/qf/Alcedo/code/ai-collab-starter/scripts/archive-progress.sh --keep-days 7
```

期望:扫 DeviceOps `.ai/progress.md`(1636 行 / 跨度 2026-05-09 → 2026-05-26 / 17 天),归档 ≥ 7 天前的段。

实际:

```
[scan] 共 0 段；保留 0 段；归档 0 段
[done] 无需归档
```

零段扫到,无任何归档。Human 误以为"自检建议有 bug"或"段头格式不对",回报"对吗?"。

## 根因

`scripts/archive-progress.sh` 第 41 行:

```bash
DEVOPS_ROOT="${DEVICEOPS_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
```

默认值用 **`$(dirname "$0")/..`** —— 即**脚本自己所在目录的父目录** —— 当用户用绝对路径从 derived 项目目录调用脚本时,`dirname "$0" = /Users/.../ai-collab-starter/scripts`,`.. = /Users/.../ai-collab-starter/` —— 解析到 **starter 自己的 .ai/progress.md**(1.2KB,只几条段,大多在 7 天阈值内),所以"0 段需归档"在 starter 侧是真结果,但对 DeviceOps 完全无意义。

Workaround(Claude 给 Human 的提示):

```bash
DEVICEOPS_ROOT=/Users/qf/Alcedo/code/DeviceOps \
  bash /Users/qf/Alcedo/code/ai-collab-starter/scripts/archive-progress.sh --keep-days 7
```

需要显式 env var 才能跑对——但 AGENTS.md v5.2.0-rc2 progress.md 行数自检条目里**没提**这个 env 要求,用户照建议跑必然踩坑。

## 影响

- 用户首次跑必失败(silent failure · 输出"无需归档"看着 normal,实际啥都没做)。
- AGENTS.md v5.2.0-rc2 finding-27 加的"progress.md 行数自检"三档阈值机制**失效**——硬触发(≥ 2000 行)
  在用户不知道 env var 要求时也不会真归档,只会 silently 0 段。
- v5.2.0-rc2 dogfood 的"防止 18 个月零触发"防线被 bypass。

## 提议

修脚本第 41 行:

```bash
DEVOPS_ROOT="${DEVICEOPS_ROOT:-$PWD}"
```

**默认用调用方 `$PWD`** —— 用户从 DeviceOps 目录跑就扫 DeviceOps,从 lite 跑就扫 lite,无需 env var,
"在哪儿喊在哪儿落"的 Unix 工具直觉对齐。

显式声明 `DEVICEOPS_ROOT` 时仍优先(向后兼容)。

**额外建议**(可选):

1. 脚本启动行加 sanity check:`[[ ! -f "$DEVOPS_ROOT/.ai/progress.md" ]] && echo "找不到 $DEVOPS_ROOT/.ai/progress.md,请 cd 到项目根或设 DEVICEOPS_ROOT 环境变量" && exit 1` —— 避免"silent 0 段"误导用户。
2. AGENTS.md v5.2.0-rc2 finding-27 三档阈值段的建议命令文本顺手改为不带绝对路径的相对调用:
   `bash <starter>/scripts/archive-progress.sh --keep-days 7`(让用户意识到 cd 到项目根才能跑)。

## 适用范围

凡 starter 派生的所有 derived 项目(目前 DeviceOps / lite / payment-recon-demo)受同一 bug 影响,
首次用 progress.md 行数自检建议时全会踩。

## 来源

- 实战 case: DeviceOps M3-Beta-Scale epic intake 后(2026-05-26 16:30)Human 按 state.md Notes
  建议跑 archive,出 "0 段" 错误结果。
- 已 Workaround:Claude 给 Human 显式 env var 命令,临时绕过。
- 相关 finding:#27(progress.md 行数自检三档阈值机制)——本 finding 是其消费侧的脚本默认值 bug。

---

## 实施记录(v5.3.0-rc1 · 2026-05-29)

- `scripts/archive-progress.sh`:默认 root 由 `$(dirname "$0")/..` 改为 `$PWD`(+ 注释说明);找不到 progress.md 时错误信息补 cd/DEVICEOPS_ROOT 提示 + finding-29 锚点。
- `AGENTS.md`:progress.md 行数自检段补「跑 archive 两个前提」(从项目根跑 / 0 归档不一定是 bug)。
- 验证:从 DeviceOps cwd 跑 dry-run 扫到 49 段(修复前扫 starter 自己 = 0 段);DEVICEOPS_ROOT 显式仍优先;`bash -n` PASS。
- 关联 commit:见 CHANGELOG v5.3.0-rc1。
