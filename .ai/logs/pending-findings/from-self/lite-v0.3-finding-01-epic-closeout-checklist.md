---
finding-id: lite-v0.3-finding-01-epic-closeout-checklist
severity: P2
category: doc + new-capability + prompt
source-project: lite-self (v0.3.0-lite-rc1 dogfood)
discovered: 2026-05-18
target:
  - .ai/workflow.md (新增 §9. Epic closeout 段)
  - .ai/getting-started.md (新增 §四. epic 收口 段 或 §〇 加链接)
  - .ai/state.md (维护规则 4 加链接到 §9)
  - .ai/prompts/09-codex-closeout.md (新 prompt, 类似 01-intake 反过来)
status: pending
related: [F12, F14]
---

# Finding F01-self: Epic 收口 (closeout) 没有统一 checklist, cleanup 纪律分散三处

## 现象

lite v0.3.0-lite-rc1 dogfood (smart-uite + Daemon singleton bug) 完成后, Human 问 "每一个问题或需求跑完了, 怎么清空 lite 框架?" — 当前 lite **没有统一回答**:

cleanup 纪律分散在 3 处:
- `.ai/state.md > 维护规则 4`: 只说 "清空 Active task / Last completed step / Next step, 仅保留 Notes" (3 段重置, 没说其它)
- `.ai/workflow.md §8.4 OC-impl 子任务包文件`: "epic 结束 Human 可清空 .ai/scratch/; 若需归档审计, Human cp 到 .ai/logs/archived/<epic-id>/ 保留"
- `.gitignore`: 隐含 `.ai/scratch/` 不入版本控制 (推断行为, 没显式纪律)

**漏写**:
- `.ai/tasks/<完成 task>.md` 归不归档 (留作 epic 文档 vs mv 到 archived)
- `.ai/review.md` finding 状态翻转 (verified / closed) 还是删行
- `.ai/progress.md` epic 收口要不要 append 总结一行
- `AGENTS.md > Known Sharp Edges` 是否需 append 新坑
- chat sessions (T1-T4) 该关 / 该新建
- 综合 cleanup checklist (一键照做)

## 影响

- Human 不知道清哪些 / 留哪些, 易出两种错:
  - **清漏**: `.ai/scratch/` 残留 → 下个 epic 启动时 OC-helper req/out / 子任务包文件混杂, false context
  - **清过头**: 误清 `.ai/decisions.md` ADR / `.ai/progress.md` 历史 / `.ai/tasks/` 完成的 task → 审计追溯断
- 下个 dogfood 启动时 context 污染 (旧 epic 的 state.md / scratch 残留干扰新 task)
- lite 设计 "每 epic 全新 session" (workflow §0 epic 间清零) 在物理层面 (文件) 没对应清理纪律

## 根因

lite v0.1.0 设计期重点放在 "session 内隔离" (workflow §0 + Pattern A), 没覆盖 "epic 收口物理清理"。
v0.2 / v0.3 增加新文件 (`.ai/scratch/oc-impl-package-*.md` · F14, `.ai/scratch/gitnexus-*-*.md` · F04) 让 scratch 内容更多元, cleanup 范围扩大但没更新纪律。

## 证据

- 本对话 2026-05-18 Human 在 v0.3 release 后立刻问 "每一个问题或需求跑完了, 怎么清空 lite 框架?"
- Claude 即兴整理出 "epic 收口 checklist" 8 项 (清/留/可选 三类), 但临时回答非契约
- smart-uite 当前残留: `.ai/scratch/` (Daemon bug epic 工作产物) + `.ai/state.md` (smart-uite epic 数据未重置) + `.ai/tasks/bug-2026-05-17-daemon-singleton-broken.md` (完成 task 未归档)

## 提议修复

### 1. **`workflow.md` 新增 §9. Epic closeout (收口)** (~ 80 行)

包含完整 cleanup checklist:

```markdown
## 9. Epic closeout (收口 · v0.4 新增 · F01-self)

epic merge 完成后, Human (或 09-codex-closeout 协助) 跑下列 checklist。

### 清 (per-epic ephemeral)

| 文件/目录 | 操作 |
|----------|-----|
| `.ai/state.md > Active task` 段 | 全 6 字段 → NONE; 当前 epic 终端布局 → T1-T4 "空闲" |
| `.ai/state.md > Last completed step` 段 | 全 5 字段 → NONE |
| `.ai/state.md > Next step` 段 | 全 6 字段 → NONE |
| `.ai/state.md > Blockers` | → "无" |
| `.ai/scratch/oc-helper/*` | 选项 A 直接 rm / 选项 B 先 cp 到 .ai/logs/archived/<epic-id>/scratch/ 再 rm |
| `.ai/scratch/oc-impl-package-*.md` | 同上 (v0.2 F14 落档纪律) |
| `.ai/scratch/gitnexus-*-*.md` | 同上 (v0.2 F04 双路并行产物) |

**保留**: state.md > Notes 段 (含 epic 总结 / merge commit hash / followup) / 维护规则段 / Pattern A/B 安全栏段 / 字段完整性硬约束段。

### 留 (持久 / 审计追溯)

| 文件 | 收口操作 |
|------|---------|
| `.ai/progress.md` | append 一行: "<date> · <epic-id> merge commit <hash> · <一句话 outcome>" |
| `.ai/decisions.md` | 不动, ADR 永久保留 |
| `.ai/review.md` | finding status 翻 `verified` / `closed`, 行不删 |
| `.ai/architecture.md` / `.ai/context.md` | 不动 (本 epic 引入了 architecture 变化才更新) |
| `.ai/tasks/<完成 task>.md` | 默认保留 (epic 文档); ≥ 1 月后归档可 mv 到 .ai/logs/archived/<epic-id>/ |
| `AGENTS.md > Known Sharp Edges` | 本 epic 踩了新坑就 append 一条 |
| `.ai/logs/pending-findings/` | 本 epic 产生的 finding 已双写到 lite inbox (getting-started §〇 约定), 此处保留本地 finding |

### 可选清理

- T1-T4 chat sessions: 本 epic 用完关掉, 下个 epic 开全新 session (workflow §0 "epic 间清零")
- Codex Desktop / OpenCode Desktop chat 历史: 删本 epic session 释放 token context

### 收口验证 (机器化)

```bash
# state.md 已重置
grep -c 'NONE' .ai/state.md  # ≥ 14 (Active task 4 + Last 5 + Next 6 - 1 起始时间例外)
# scratch 已清
ls .ai/scratch/oc-helper/ .ai/scratch/oc-impl-package-*.md .ai/scratch/gitnexus-*-*.md 2>/dev/null | wc -l  # 应 = 0
# progress.md 含 epic 收口行
grep -c "<epic-id>" .ai/progress.md  # ≥ 1
```
```

### 2. **新 prompt `.ai/prompts/09-codex-closeout.md`** (~ 60 行)

类似 01-intake 反过来: Human 一句话 "epic <id> 完了" + Codex 跑 4 步 closeout:

```markdown
# Prompt: Codex 09-closeout · Epic 收口 (lite v0.4)

## 角色
Codex 协助 epic 收口: Human 一句话触发, Codex 跑 cleanup checklist + 验证 + 刷 state.md。

## 输入
- 一句话 "epic <id> 完了, merge commit <hash>, outcome: <一句话>"
- workflow.md §9 checklist

## 4 步流
Step 1: 验证前置条件 (.ai/review.md 无 open finding / merge commit 存在 / state.md `Active task.当前 task` 与 epic 一致)
Step 2: 清 (按 §9 checklist 清单 · scratch / state.md 字段重置)
Step 3: 留 (按 §9 checklist 追加 progress.md / 翻 review.md status / 评估 AGENTS.md Known Sharp Edges 是否需 append)
Step 4: 收口验证 (机器化 grep 3 项), chat 输出 "closeout done, 下个 epic 全新 session"

## 禁止
- 跳过 Step 1 前置条件验证 (review.md 有 open finding 时不能收口)
- 删 .ai/tasks/<task>.md / .ai/decisions.md / .ai/progress.md (这些是审计追溯)
- 在没 merge commit 时收口 (epic 没真完成)
```

### 3. **`state.md > 维护规则 4`** 加链接

```markdown
4. 任务整体完成(merge + 文档收口都做完):**走 workflow.md §9 Epic closeout 完整 checklist** (不只是清空 Active task / Last completed step / Next step 三段, 还涉及 .ai/scratch/ 清理 / progress.md append / review.md status 翻转 等)
```

### 4. **`getting-started.md`** 新增 §四 收口段 (或 §〇 加链接)

```markdown
## 四 · Epic 收口 (v0.4 新增 · F01-self)

epic merge 完, 跑 `workflow.md §9` checklist 或喂 `.ai/prompts/09-codex-closeout.md` 给 Codex。
不收口 = 下个 epic 启动时 context 污染 (旧 epic 的 state.md / scratch 残留)。
```

## SemVer 影响

**MINOR** (新增能力 · 09-closeout prompt + workflow §9 + getting-started §四; 旧 v0.3 项目不走 closeout 仍合法 (state.md 维护规则 4 旧版本仍兼容), 只是没机器化保障)。
