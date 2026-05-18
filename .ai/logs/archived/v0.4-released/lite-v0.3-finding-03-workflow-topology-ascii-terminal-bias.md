---
finding-id: lite-v0.3-finding-03-workflow-topology-ascii-terminal-bias
severity: P3
category: doc
source-project: lite-self (v0.3.0-lite-rc1 dogfood · smart-uite Human 修正)
discovered: 2026-05-18
target:
  - .ai/workflow.md (§0 4 终端拓扑图说明)
status: implemented-in-v0.4.0-lite-rc1
related: [F02-self]
---

# Finding F03-self: workflow.md §0 4 终端拓扑 ASCII 图 implicit 假设是终端 (CLI/TUI), Desktop / GUI 形态没显式说明

## 现象

`workflow.md §0` 当前 ASCII 图:

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ T1: Codex    │   │ T2:OC-helper │   │ T3: OC-impl  │   │ T4: OC-review│
│ (主驱动)      │   │ (grep/scan)  │   │ (写代码)      │   │ (独立审)      │
│ 长 session    │   │ 长 session    │   │ 长 session    │   │ 长 session    │
│ per epic     │   │ per epic     │   │ per epic     │   │ per epic     │
└──────┬───────┘   └──────▲───────┘   └──────▲───────┘   └──────▲───────┘
       ...
```

"T1 / T2 / T3 / T4" 命名 + 4 列并排显示 → **暗示 4 个并排终端 (tmux panes / iTerm tabs)**。Desktop 用户看图困惑: "我没有 4 个并排终端, 只有 Codex Desktop + OpenCode Desktop 两个 app"。

实际 lite 设计意图: T1-T4 是 **session 抽象**, 不是 4 个物理终端。Desktop 用户实际是 "2 app × 4 sessions" (Codex Desktop 1 session = T1, OpenCode Desktop 3 sessions = T2/T3/T4)。

## 影响

- 不严重 (P3, 纯文档表述, 跟 F02-self 同根)
- Desktop 用户首次看 §0 图会按字面理解 "需要 4 个终端", 不知道可以是 chat sessions
- 长期: lite 默认假设应转向 Desktop 形态 (主流), 终端形态降级为 "可选"

## 根因

同 F02-self: lite v0.1.0 设计期默认 CLI/TUI 视角, ASCII 图传达终端形态偏见, 没显式说"T1-T4 是 session 抽象, 任何 UI 形态都可实现"。

## 证据

- 2026-05-18 Human 在 v0.3 dogfood 期间修正 (同 F02-self 证据)

## 提议修复

**`workflow.md` §0 4 终端拓扑** 段 ASCII 图保留 (作为抽象示意), 但**图下方加说明**:

```markdown
## 0. 4 终端拓扑 (session 抽象, 不绑 UI 形态)

> **T1-T4 是 session 抽象**, 不是 4 个物理终端。实际形态见 `.ai/getting-started.md §一 Step 3` (Desktop / tmux / iTerm 三选)。
>
> "T" 代表 "Terminal" 是 lite v0.1.0 命名遗留 (作者当时假设 CLI/TUI), v0.3 后建议读作 **"Track" (轨道)** 更准确: 每个 Track 是一个独立的 agent session, 跨 epic 不复用。

[ASCII 图保留]

### Session 隔离规则 (强制)
[沿用现有表]
```

并在表第一行加 Desktop 形态对照:

```markdown
| 抽象 (Track) | Desktop app sessions | CLI/TUI |
|-------------|---------------------|---------|
| T1 (Codex) | Codex Desktop chat 1 | tmux/iTerm pane 1 |
| T2 (OC-helper) | OpenCode Desktop chat 1 | pane 2 |
| T3 (OC-impl) | OpenCode Desktop chat 2 (独立 session 防自审) | pane 3 |
| T4 (OC-review) | OpenCode Desktop chat 3 (独立 session 防自审) | pane 4 |
```

## SemVer 影响

**PATCH** (纯文档说明增量, 不改 ASCII 图本体, 不破坏旧 CLI/TUI 用户体感)。

## 关联与对照

- 与 **F02-self** (getting-started §一 Step 3 tmux hint) 同根: F02 修用户入口, F03 修概念图。两者一起 sync 完整覆盖
- 长期 v1.0 stable 可考虑: 把 T1-T4 命名改成 "Track 1-4" / "Session 1-4" 彻底去终端味儿, 但这是 MAJOR breaking, 留 v1.0 决策

---

## v0.4.0-lite-rc1 实施记录 (2026-05-18)

- **release**: v0.4.0-lite-rc1
- **触发来源**: lite-self dogfood (smart-uite v0.3.0-lite-rc1 daemon-business-manager-not-started bug epic 跑完 lite v0.3 全流程 + Human 修正 Desktop UI 模型 + 主动询问 closeout 纪律)
- **实施摘要**: 详见 `CHANGELOG.md > [v0.4.0-lite-rc1]` Added/Changed 段, 本 finding (F03-self) 落入对应分组
- **archive 路径**: `.ai/logs/archived/v0.4-released/lite-v0.3-finding-03-workflow-topology-ascii-terminal-bias.md`
