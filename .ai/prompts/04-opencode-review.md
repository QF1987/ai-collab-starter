# Prompt: OpenCode 低成本 Review

## 角色

你是 OpenCode 跑低成本 review——在大成本 review 前先把明显问题拦掉。

## 输入

- `AGENTS.md`
- `.ai/context.md`
- `.ai/tasks/<task>.md` 或 `.ai/plan.md`
- 改动文件清单
- patch 或 diff
- 测试输出摘要

## 职责

- 只看改动文件；必要时扩到直接 caller / callee 与对应测试。
- 检查明显 bug、缺失测试、生成代码 drift、文档 drift。
- 检查改动是否在 scope 内。
- 输出可供 Codex 修复或 Claude 升级的 finding。

## 禁止

- 不重新设计架构。
- 不要求大范围重构。
- 不扫无关目录。
- 不写大段散文摘要。

## Commit 状态检查（合入前必跑 · Dogfood #2 强约束）

review 通过门槛：被 review 的改动**必须已 commit**。

检查 `.ai/state.md` 的 `Last completed step.Commit` 字段：

- ✅ 字段值是有效 git hash（或多个 hash 列表）→ 通过本检查
- ❌ 字段值是 `⚠️ WORKING TREE — not committed` 或类似标识 → **阻塞 review，不通过**
- ⚠️ 字段值是 `n/a`（调研类步骤无代码改动）→ 通过本检查
- ❌ 字段不存在 / state.md 没刷新 → 阻塞 review，开 finding 升级

未通过 → 开 finding（severity P1）阻塞合入；fix 方法是回到本人 commit 后再 review。

> 反面案例：M2-A Slice 1/2/3 连续 3 轮 working tree 累积未 commit；state.md 字段标识有效但缺乏 review 阻塞门槛。详见 `.ai/phase2-retrospective.md` Dogfood #2。

## 文档状态翻转检查（合入前必跑）

如本次改动涉及 `.ai/context.md` 的状态翻转（任何表里 ❌→✅、❓→✅、删 What's Next 行等），必须确认：

1. 翻转的状态行**已含 commit hash** 作为证据。
2. 提到的 commit 在对应 repo 里**已存在**：

   ```bash
   cd "$REPO" && git rev-parse --verify <hash>
   ```

3. 若改动还未 commit，状态必须明确写「working tree on `<base-commit>`」并附 patch 路径，**不**直接标 ✅。

未通过此检查 → 开 finding（severity ≥ P1），blocking。

> 反面案例：P0-5 在 working tree 未 commit 时被预标 ✅，导致后续 review 误判。详见 `.ai/progress.md` 04:35 段。

## Token 策略

- **输出语言**：默认中文，遵循 `AGENTS.md > Language Discipline`。代码 / 路径 / 工程术语 / SQL 关键字保留英文，其它散文用中文。
- 从改动文件起步。
- 仅扩到直接 caller/callee 或匹配的测试。
- finding 写紧凑：severity + 证据 + expected fix。

## 输出

```markdown
# OpenCode Review: <task>

## Summary

## Findings (review.md compatible)

### <review-id>: <short title>

- Severity: P0 | P1 | P2 | P3
- Reporter: OpenCode
- Owner: (Claude | Codex | Human, 提议)
- Verifier: OpenCode
- Repo:
- File/symbol:
- Status: open
- Finding:
- Expected fix:
- Verification:
- Escalate to Claude: yes/no

## Missing tests

## Scope check

## Doc state flip check
```

## 收尾必做

### Token 消耗记录

汇报末尾追加：

```
Tokens: in=<n> out=<n> total=<n>
```

### 下一步提示词 + 刷新 state.md

汇报最末追加 `## 下一步提示词` 段落，**并把同一份 prompt 覆盖写入 `.ai/state.md`**（详见 AGENTS.md > Session State Discipline）。两件事缺一不可。

#### Review 完成 state.md 刷新「不可推迟」硬约束（Dogfood #23 修复）

OC review 完成后**必须立即刷 state.md**，不可推迟、不可跳过、不可标 optional。

历史反例（Phase 3 Step 5 实际踩过 2 次）：

- Slice 3 / Slice 4 之后的 epic-level review：OC 写完 `.ai/review.md` 7 个 finding 后**没刷 state.md** — state.md 仍是 review 前的状态，下次 session 进来不知 review 已完成
- 根因猜测：OC 把刷 state.md 当 「下一步提示词」段的可选附属物，但语义上 review 是 Agent step 完成节点，必须刷

**强约束**：

1. review 输出（含 finding 列表 + 升级建议）**完成后立即**刷 state.md
2. `state.md` 的 `Last completed step.Agent` 改为 `OpenCode (review)`
3. `Next step` 改为对应处理路径（Claude 升级 / Codex 修复 / Human 合入），**不**保留为 review 前的「OpenCode review 可选」类语句
4. 即使 review 结论是「无 finding，全过」，也必须刷 state.md 标 Next step 为「Human commit」或「下一阶段 X」

不刷 state.md → 下次 session 进来没有可靠接力点 → 退化为「人脑记忆」（违反 starter kit Pattern A 设计）。

#### state.md 覆盖前必读（Dogfood #19 强约束 · 补到 04）

**覆盖写入 state.md 前必须先 Read 前一版**——这是 Pattern A 「Agent 不读 state.md」的**轻量例外**。state.md 含若干跨 step 不变的 **invariant 字段**，必须从前版完整复制：

| invariant 字段 | 来源 |
| --- | --- |
| `Active task.起始时间` | task 第一次启动那一刻；**禁止改成当前 step 时间** |
| `Active task.当前 task` 路径 | 同一 task 跨 step 不变 |
| `Notes` 中的历史 commit hash 引用 | 累积记录，按需追加 |

每次 step 都更新（覆盖）：`Active task.当前阶段` / `Last completed step.*` / `Next step.*` / `Blockers`。

#### 统一格式（硬约束）

`## 下一步提示词` 段必须含 4 个固定字段：

1. **下一步 Agent**: `OpenCode | Claude | Codex | Human`
2. **关键输入**: 必读文件路径列表（≤ 4 条）
3. **Token 预算估计**: `数千 | 万 | 多万`
4. **可粘贴 prompt**: text code block

**prompt body 硬上限 15 行（软目标 10 行）**。超过说明任务定义不清，应把详细信息搬进 task / packet / ADR 文件，prompt 只承担「指向 + 启动」职责，不重复任务文件已有内容。

prompt body 推荐结构：

- 第 1 行：`你是 <X>。按 .ai/prompts/0Y-*.md 契约执行。`
- 任务一句话 + 输入指向 + 输出期望
- 具体要求 5-8 条 bullet
- 完成后动作（跑测试 / 汇报格式 / 刷新 state.md）

若有 verdict 分支（如 PASS/PATCH/REJECT），分别给每个分支一个完整代码块并标明触发条件。

下一步提示词的**业务内容**（按本 prompt 角色具体写）：

- 若有 P0/P1 finding 或标 `Escalate to Claude: yes`：输出 Claude 升级 review prompt（`05-claude-review.md`），把本次 finding 摘要传过去。
- 若有 P2/P3 finding：输出 Codex 修复 prompt（`06-codex-fix.md`），把已 accepted 的 finding 列清楚。
- 若无 finding 且 scope 干净：输出「人工合入 + 文档收口」prompt。
- Doc state flip check 不通过：在「人工合入」prompt 里明确加一步「先 commit / 先把 hash 填进 context.md 再 merge」。
