---
finding-id: lite-v0.3-finding-02-desktop-ui-doc-anachronism
severity: P3
category: doc
source-project: lite-self (v0.3.0-lite-rc1 dogfood · smart-uite Human 修正)
discovered: 2026-05-18
target:
  - .ai/getting-started.md (§一 Step 3 重写, 加 Desktop 模式)
  - .ai/workflow.md (§0 4 终端拓扑图说明 加 "Desktop app sessions 等效")
status: implemented-in-v0.4.0-lite-rc1
related: [F03-self]
---

# Finding F02-self: getting-started.md §一 Step 3 "推荐 tmux 布局" hint 对 Codex Desktop / OpenCode Desktop 用户不适用

## 现象

v0.3 dogfood 期间, Human 修正 Claude 的理解 "Codex Desktop 和 OpenCode Desktop 不是开 4 个 app 窗口, 只是开不同的会话"。

lite `getting-started.md §一 Step 3 开 4 终端` 当前文本:
```text
# 推荐 tmux 布局:
tmux new -s lite-epic-<name>
# 然后:
#   Ctrl-B "    水平分屏
#   Ctrl-B %    垂直分屏
# 直到 4 panes:
#   T1 (top-left)     : codex
#   T2 (top-right)    : opencode (OC-helper, 按需启动)
#   T3 (bottom-left)  : opencode (OC-impl)
#   T4 (bottom-right) : opencode (OC-review)

# 或 iTerm 4 个 tab 分别命名。
```

这套是 **CLI/TUI 时代**指引: tmux panes / iTerm tabs。**Codex Desktop / OpenCode Desktop 等 GUI app 用户照不了**, 实际模型应该是 "**2 app × 4 sessions**":

| 抽象 (lite 框架) | Desktop 实际 |
|----------------|-------------|
| T1 Codex | Codex Desktop 中 1 个 chat 会话 |
| T2 OC-helper | OpenCode Desktop 中 1 个 chat 会话 |
| T3 OC-impl | OpenCode Desktop 中**另一个** chat 会话 |
| T4 OC-review | OpenCode Desktop 中**第三个** chat 会话 |

## 影响

- 不严重 (P3, 纯文档表述): 不影响契约 / 不影响 dogfood 跑通 (smart-uite 已经用 Codex Desktop + OpenCode Desktop dogfood 跑通了 Daemon 单例 bug epic)
- 但: Desktop 用户初次接 lite 看 §一 Step 3 会困惑 "tmux 是啥" / "为啥要 4 个终端", 实际只需"开会话"
- 长期看: GUI 用户应是 lite 默认假设 (Codex CLI 用户少, Desktop / IDE 集成是主流), CLI/TUI hint 应降级为 "可选参考"

## 根因

lite v0.1.0 设计期作者 (Human + Claude) 假设 Codex CLI / OpenCode CLI 是主入口, 文档默认 CLI 视角。
Codex Desktop / OpenCode Desktop 是后续主流形态, lite 文档未更新。

## 证据

- 2026-05-18 Human 在 v0.3 dogfood 期间修正: "Codex desktop 和 opencode desktop 不是开了 4 个 app 窗口, 只是开不同的会话"
- 当前 §一 Step 3 完整 11 行 hint 仅讲 tmux + iTerm, 0 行讲 Desktop

## 提议修复

**`getting-started.md` §一 Step 3** 重写为 3 段 (按 UI 类型分):

```markdown
### 3. 开 4 终端 / 4 会话 (3 分钟)

lite 的 "4 终端" 是 **session 抽象**, 不绑死 UI 形态。任选一种实际形态:

#### 形态 A · Desktop app (推荐 · 主流)

- **Codex Desktop**: 开 1 个 chat 会话 (= T1 lead engineer)
- **OpenCode Desktop**: 开 3 个独立 chat 会话 (= T2 OC-helper / T3 OC-impl / T4 OC-review)
  - 关键纪律 (workflow §0): T3 OC-impl ↔ T4 OC-review **必须不同会话** (防自审盲点)
- Human 在两个 app 间切 + 复制 prompt (Pattern A)

#### 形态 B · tmux 4 panes (CLI / TUI 用户)

```bash
tmux new -s lite-epic-<name>
# Ctrl-B "    水平分屏
# Ctrl-B %    垂直分屏
# 直到 4 panes:
#   T1 (top-left)     : codex
#   T2 (top-right)    : opencode (OC-helper, 按需启动)
#   T3 (bottom-left)  : opencode (OC-impl)
#   T4 (bottom-right) : opencode (OC-review)
```

#### 形态 C · iTerm 4 tabs (CLI / TUI 用户 · macOS)
4 个 tab 分别命名 T1-T4 跑对应 agent。

#### 单终端探索模式 (Tiny / Small 初次试水, 任意形态都可降级)
- T1 Codex 同时模拟 OC-impl (临时授权, 标 `human-override-codex-fix`)
- T4 OC-review 仍开独立 session (防自审盲点)
- T2 OC-helper 不需要
```

## SemVer 影响

**PATCH** (纯文档增量, 不改 prompt 契约; 旧 CLI 用户照原 hint 仍能跑)。

## 关联与对照

- 与 **F03-self** (workflow.md §0 4 终端拓扑图 implicit 假设终端) 同根: F02 修 getting-started 用户入口, F03 修 workflow 概念图。两者一起 sync 才完整覆盖 Desktop 形态

---

## v0.4.0-lite-rc1 实施记录 (2026-05-18)

- **release**: v0.4.0-lite-rc1
- **触发来源**: lite-self dogfood (smart-uite v0.3.0-lite-rc1 daemon-business-manager-not-started bug epic 跑完 lite v0.3 全流程 + Human 修正 Desktop UI 模型 + 主动询问 closeout 纪律)
- **实施摘要**: 详见 `CHANGELOG.md > [v0.4.0-lite-rc1]` Added/Changed 段, 本 finding (F02-self) 落入对应分组
- **archive 路径**: `.ai/logs/archived/v0.4-released/lite-v0.3-finding-02-desktop-ui-doc-anachronism.md`
