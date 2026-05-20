---
finding-id: lite-v0.7-finding-07-verifier-script-200-line-cap
severity: P2
category: prompt + 03a-decompose-gap
source-project: smart-uite (bug-20260520-daemon-reader-device-prompt-loop 03c round2 REJECT + bug-20260520-h5coat-tray-white-screen 03c round2 REJECT · 2 epic 同日同根)
discovered: 2026-05-20
target:
  - .ai/prompts/03-codex-orchestrate.md (03a 子任务包模板: dedicated verifier/test 脚本预声明行数预算)
  - .ai/oc-code-quality-rubric.md (H5 注释: 区分业务代码 vs 专用 verifier/test 文件)
status: pending
related: [F-H5-cap]
---

# Finding F07-v0.7: 单文件 200 行硬上限反复误伤 verifier/test 脚本, 03a 没主动用预声明例外

## 现象

同一天两个 P0 epic, 03c 各被 H5 (单文件 diff > 200 行) 退回一次:

- `bug-20260520-daemon-reader-device-prompt-loop` 03c round2 REJECT: verifier `windows_verify_reader_startup_config.ps1` 208 行超 200 上限, retry 后压到 145 行才过。
- `bug-20260520-h5coat-tray-white-screen-qt5core-missing` 03c round2 REJECT: verifier `windows_verify_h5coat_white_screen.ps1` 205 changed lines (202 insert + 3 delete) 超 200 上限。

两轮 REJECT 都纯粹是行数问题, 不是逻辑问题——verifier 脚本本身质量没问题, 只是被一刀切的 200 行 cap 拦了。

## 影响

- **诊断/验证型脚本天然偏长**: 一个完整 verifier 要做文件存在性 + hash + 依赖闭包 + 导出信号 + negative case 多道 gate, 200 行很容易超。两个 epic 各浪费一轮 retry 压行数。
- **机制其实已存在但没被用**: H5 cap 原文写了「单文件 diff > 200 行 → 自动 fail (除非子任务包显式预声明)」。例外通道存在, 但 **03a 拆诊断/验证型子任务包时没主动声明 verifier 脚本的行数预算**, 于是默认撞 cap。
- **成本不对称**: 修复逻辑没问题, 却因为 03a 漏了一个预声明动作, 两个 epic 共烧 2 轮 retry。

## 根因

`03-codex-orchestrate.md > 03a 子任务包模板` 的「禁止」段固定写「单文件 diff > 200 行 (超了停下来问)」, 但 03a 拆**含 dedicated verifier/test 脚本**的子任务包时, 没有强约束要求 Codex 预估该脚本规模并在子任务包里**显式预声明行数预算**。

`oc-code-quality-rubric.md` 的 H5 也没区分「业务代码」vs「专用 verifier/test 脚本」——后者本就该有更宽的预算。

## 证据

- smart-uite `bug-20260520-daemon-reader` 会话归档 §7.2: 「新增 verifier 为 208 行, 超过子任务包和 rubric 的单文件 200 行硬上限」→ 03c round2 REJECT。
- smart-uite `bug-20260520-h5coat-tray` 会话归档 §5: 「verifier 单文件 202 insertions / 3 deletions = 205 changed lines, 超过 ≤200 上限」→ 03c round2 REJECT。

## 提议修复

### 1. `03-codex-orchestrate.md > 03a 子任务包模板` 加 verifier/test 脚本行数预声明

```markdown
### 必做 (Codex 03a 写本段时遵守)
...
(v0.7 · F07-v0.7) 若本子任务包含 dedicated verifier / test 脚本 (非业务代码),
03a 必须预估其规模, 在子任务包「禁止」段把默认 200 行 cap 显式改写为该脚本的预算:
- e.g. "verifier 脚本 windows_verify_X.ps1 预算 ≤ 220 行 (含 N 道 gate), 业务代码仍 ≤ 200 行"
- 预算应贴合 gate 数量, 不是无脑放宽; 预算外仍 fail
```

### 2. `oc-code-quality-rubric.md > H5` 区分文件类型

```markdown
H5: 单文件 diff > 200 行 → fail。例外:
- 子任务包显式预声明的行数预算 (业务代码 / verifier 脚本各自预算)
- dedicated verifier/test 脚本: 子任务包未预声明时默认放宽到 250 行 (gate 密集型天然偏长),
  业务代码无预声明仍 200 行
```

## SemVer 影响

**MINOR** (03a 模板加预声明子句 + rubric H5 注释细化 · 不破坏 v0.6 旧子任务包 · 旧子任务包无预声明仍按 200 行判)。

## 关联

- 与 lite H5 硬门槛设计同源: H5 cap 本为防业务代码大段越界, 对 verifier 脚本是误伤。
- 跨 epic 累积: 2 个 epic 同日同根触发, 信号强 (P2 by 复发)。

---

## v0.7 实施记录 (2026-05-20)

本 finding 在 `v0.7.0-lite-rc1` release 消化。实施详情见 `CHANGELOG.md` `[v0.7.0-lite-rc1]` 段。
