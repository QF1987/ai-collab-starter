---
finding-id: lite-v0.7-finding-11-tool-agnostic-role-naming
severity: P2
category: naming + tool-coupling + MAJOR
source-project: lite-self (Human 决策: OpenCode 配国产模型实战效果不行, 拟改用 Claude Code 配国产模型跑 worker 角色)
discovered: 2026-05-20
target:
  - .ai/prompts/*.md (全部 prompt 文件 · 含 oc-helper.md / 03b-opencode-impl.md / 04-opencode-review.md / 01-opencode-context.md / 07-opencode-draft.md 重命名)
  - .ai/state.md (角色名 / 终端布局字段)
  - .ai/workflow.md (4 终端拓扑 / Track 表 / 角色描述)
  - AGENTS.md (角色定义 / Language Discipline)
  - VERSION / CHANGELOG.md (MAJOR bump)
status: pending
related: [F03-self]
semver: MAJOR
---

# Finding F11-v0.7: lite 角色名绑死工具 (Codex / OpenCode), 工具一换名字即过期 — 改为函数式工具无关命名

## 现象

lite 当前 4 个 Agent 角色名直接绑工具:

- `Codex` (T1 lead engineer) — 绑 Codex 工具
- `OC-helper` / `OC-impl` / `OC-review` (T2/T3/T4) — `OC` = OpenCode

Human 实战反馈: **OpenCode 配国产模型效果不行**, 拟改用 **Claude Code 配国产模型**跑 worker 三角色。一旦换工具:

- 仍叫 `OC-*` → 名实不符 (跑在 Claude Code 上却叫 OpenCode)
- 改叫 `Claude-*` → 与 main starter (真有 Claude 角色) 概念撞车, 产生混淆

## 影响

- **角色名是工具的函数, 不该是**: 角色的本质是**职责** (lead 架构/拆任务/验收, helper 全仓搜索, impl 写代码, review 独立审), 跟跑在什么工具上无关。绑工具命名 = 每次换工具就要改一遍框架。
- **同一个教训框架已踩过一次**: `workflow.md §0` 记录 v0.4 · F03-self 已经把 `T1-T4 = Terminal` 重新定义为 `Track (轨道)` —— 因为 Terminal 绑死了 CLI/TUI 形态假设。F11 是同一个错误的另一个实例 (这次绑的是工具品牌而非 UI 形态)。
- **prompt 文件名也绑死**: `oc-helper.md` / `03b-opencode-impl.md` / `04-opencode-review.md` / `01-opencode-context.md` / `07-opencode-draft.md` 文件名含 `opencode` / `oc`, 重命名文件 → 触发 MAJOR。

## 根因

lite v0.1.0 bootstrap 时直接用当时选定的工具品牌命名角色 (Codex Desktop + OpenCode Desktop), 没有引入「角色名工具无关」的设计纪律。v0.4 F03-self 修了 Terminal→Track 但没顺带修角色名。

## 提议修复

### 1. 角色重命名 (函数式 · 工具无关)

| 现名 | 新名 (函数式) | 职责 |
|------|--------------|------|
| Codex | **Lead** | 架构 / 拆任务 (03a) / 验收 (03c) / intake / closeout |
| OC-helper | **Helper** | 全仓搜索 / scan / summarize |
| OC-impl | **Impl** | 写代码 |
| OC-review | **Reviewer** | 独立审 (与 Impl 强制隔离) |

> 新名只描述职责, 不含任何工具品牌。实际跑在什么工具上 (Claude Code / Codex / OpenCode / 其它),
> 由 `getting-started.md` 的「Track ↔ 工具形态对照表」说明, 与角色名解耦 (沿用 v0.4 Track 对照表模式)。

### 2. prompt 文件重命名

```
oc-helper.md            → helper.md
01-opencode-context.md  → 01-context.md
03b-opencode-impl.md    → 03b-impl.md
04-opencode-review.md   → 04-review.md
07-opencode-draft.md    → 07-draft.md
(02-codex-plan.md / 03-codex-orchestrate.md / 06-codex-fix.md / 08-codex-audit.md /
 09-codex-closeout.md / 01-codex-intake.md 的 "codex" 同理 → "lead" 或去前缀)
```

### 3. 全仓引用替换

state.md / workflow.md / AGENTS.md / 所有 prompt 内的 cross-reference / 阶段枚举 / 终端布局字段
里的 `Codex` / `OC-*` / `OpenCode` 角色引用全部 sync 到新名。
**保留** Track (T1-T4) 抽象不变 —— Track 已是工具无关的, 只换挂在 Track 上的角色名。

### 4. CHANGELOG Breaking changes 段显式列契约变更

旧 prompt 路径 / 旧角色名失效, derived 项目 sync 时需对照映射表更新引用。

## SemVer 影响

**MAJOR → v0.7.0-lite** (重命名 ≥ 5 个 prompt 文件 + 全仓角色名变更 · 按 lite SemVer 决策树「涉及删除/重命名 prompt → MAJOR」)。

> lite v0.X 期间 MAJOR 突变保留 v0.X+1.0 形式 (v0.6 → v0.7.0), 不冲 v1.0.0。

## 关联

- 与 **v0.4 · F03-self (Terminal → Track)** 同根: 都是「命名绑死了某个会变的维度」。F03 修了 UI 形态维度, F11 修工具品牌维度。
- 实施建议: 作为 v0.7 升级仪式的**主线 finding**, 与 F07-F10 一起消化。F07-F10 是 MINOR/PATCH 级增量, 可在同一次 v0.7.0 MAJOR release 里一并实施 (MAJOR release 自然吸收低级别 finding)。
- 实施纪律: 重命名是机械但易漏的全仓替换, 建议升级仪式 Step 4 用 OC-helper 跑一遍全仓 `grep` 旧名残留做收尾验证。

---

## v0.7 实施记录 (2026-05-20)

本 finding 在 `v0.7.0-lite-rc1` release 消化。实施详情见 `CHANGELOG.md` `[v0.7.0-lite-rc1]` 段。
