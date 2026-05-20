---
finding-id: lite-v0.7-finding-10-review-powershell-lang-row
severity: P3
category: prompt + review-lang-coverage-gap
source-project: smart-uite (bug-20260520-h5coat-tray-white-screen-qt5core-missing 03c round1 REJECT)
discovered: 2026-05-20
target:
  - .ai/prompts/04-opencode-review.md (第三步 3c 语言自适应 quality 表加 PowerShell 行)
status: pending
related: [F07-v0.7]
---

# Finding F10-v0.7: 04 OC-review 语言自适应 quality 表缺 PowerShell 行

## 现象

smart-uite `bug-20260520-h5coat-tray-white-screen-qt5core-missing` epic 03c 第 1 轮 REJECT, 根因是 PowerShell 解析错误:

```
windows_verify_h5coat_white_screen.ps1:620 char:24
else { warn "  $_: NOT FOUND" }
                    ~~~
InvalidVariableReferenceWithDrive
```

双引号字符串里 `$_:` 被 PowerShell 解析为 **drive-qualified 变量引用** (它把 `:` 前的当成 drive 名), 应写 `${_}: NOT FOUND`。这是 PowerShell 专属的语言陷阱。

## 影响

- **诊断/验证型脚本越来越多用 PowerShell**: smart-uite 是 Windows 系统, `interim/scripts/` 下 verifier / build 脚本全是 `.ps1`。本日两个 epic 全程 PowerShell。
- **04 语言自适应 quality 表没覆盖 PowerShell**: 现表只有「ops-only / shell scripts」一行, 列的是 bash 系陷阱 (`set -euo pipefail` / trap)。PowerShell 的陷阱 (drive-qualified 变量 / `$LASTEXITCODE` / robocopy exit code 语义 / ExecutionPolicy) 完全没覆盖, OC-review 跑不到对应检查项。
- 本次是 Codex 03c 自己 catch 到 parser error (因为脚本根本跑不起来), 但若是更隐蔽的 PowerShell 陷阱 (e.g. robocopy exit 1 被误判为失败 / `$LASTEXITCODE` 未检查), 04 review 没有对应 checklist 行就会漏。

## 根因

`04-opencode-review.md > 第三步 3c · 语言自适应 quality 子项` 表里没有 PowerShell 行。表注明确说「实战中遇到新模式可在 review.md note 一笔, 积累到升级清单」——本 finding 即该积累。

## 证据

- smart-uite `bug-20260520-h5coat-tray` 会话归档 §4: 03c round1 REJECT, parser error `InvalidVariableReferenceWithDrive`, 「双引号字符串中 `$_:` 被 PowerShell 解析为非法变量引用」。
- 同 epic §6: robocopy exit 1 / exit 11 的 exit code 语义判定 (exit 1 = 成功复制了文件) 也是 PowerShell/Windows 专属知识。
- 04-opencode-review.md 3c 表当前 6 行, 无 PowerShell 行。

## 提议修复

### `04-opencode-review.md > 3c 语言自适应 quality 子项` 表加 PowerShell 行

```markdown
| **PowerShell / Windows 脚本** | drive-qualified 变量陷阱 (`"$var: x"` 应写 `"${var}: x"`)、`$LASTEXITCODE` 显式检查、robocopy/外部命令 exit code 语义 (robocopy exit 1-7 非失败)、`-ErrorAction` / `$ErrorActionPreference` 一致性、`ExecutionPolicy Bypass` 仅限脚本入口、UNC/network-root 路径行为 |
```

放在「ops-only / shell scripts」行之后 (二者都是脚本类, 但 bash 与 PowerShell 陷阱不同, 分行避免 OC-review 跑错语言项)。

## SemVer 影响

**PATCH** (语言自适应表增量加一行 · 不破坏 v0.6 contract · 纯检查项扩充)。

## 关联

- 与 F07-v0.7 同 epic 同轮 (03c round1/round2) 触发。
- 04 语言表本就是「实战累积升级」设计 (表注 v3.0 起点), F10 是 PowerShell 形态的首次累积。

---

## v0.7 实施记录 (2026-05-20)

本 finding 在 `v0.7.0-lite-rc1` release 消化。实施详情见 `CHANGELOG.md` `[v0.7.0-lite-rc1]` 段。
