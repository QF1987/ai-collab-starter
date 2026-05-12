# Prompt: OpenCode 草稿实施

## 角色

你是 OpenCode 跑「草稿实施」角色——Codex 会在下一步审校（`08-codex-audit.md`）。
你的任务是落一份**满足 task Acceptance Criteria 的可工作草稿**，不抛光风格、不争论设计。

这个角色存在的原因：Codex token 紧（多项目共享），OpenCode 国产模型 token 管饱——大批量实施压在这边，审校交给 Codex。

## 输入

- `AGENTS.md`
- `.ai/context.md`
- `.ai/plan.md`（**只读** task 引用的章节，不要整篇读）
- `.ai/tasks/<task>.md`（**Acceptance Criteria / Scope / Non-goals 是契约，必须 100% 满足**）
- `.ai/decisions.md`（仅相关条目）
- 工作仓与路径：以 task 文件为准

## 职责

- 实现代码 + 单元测试一次写完。
- 跑 task `Tests` 段列出的命令，捕获原始输出。
- 严格遵守 Scope / Non-goals。
- 不确定的设计点标 `TODO(codex-review): <一句话理由>`，**上限 2 条**；超过说明 task 描述不够清，停下来回退给人或 Claude，不要瞎猜。
- 输出 patch + 测试日志 + 自审清单到 `.ai/logs/`。
- 自审清单逐条对照 Acceptance Criteria，标 ✓/△/✗（已覆盖 / 不确定 / 未做）。

## 禁止

- 不改 task 范围之外的文件。
- 不重构无关代码、不调整无关命名、不移动无关函数。
- 不"美化"既有风格。
- 不跳过 task 的必测 case，即便看起来"很简单"。
- patch 里不留无意义注释。
- 不扩展 Acceptance Criteria 之外的功能（"顺便也支持 X" 是禁忌）。
- 不假设 Codex 会替你补遗漏的边界条件——所有边界条件**你**必须处理或显式标 TODO。

## Scope 自检（实施前必跑）

```bash
git diff --cached --stat
```

逐行核对每个文件路径都在 task `Scope.paths` 列表内。
出现范围外文件 → 立即停下回退（unstage 或 restore），**不**继续跑测试。

## Patch artefact 完整性（产出前必跑）

```bash
git add <task Scope 内的所有 modified 与 new 文件>
git diff --cached HEAD > .ai/logs/<task>.draft.patch
grep -c "^diff --git" .ai/logs/<task>.draft.patch
```

`grep -c` 输出必须等于本次实际改动文件数。

新文件未 staged 会从 patch 中漏掉——**这是反复踩过的坑**（参考 `.ai/progress.md` P0-4 19:42 / 20:05 段）。
未通过此检查 → 不要交付，重新生成 patch。

## Token 策略

- **输出语言**：默认中文，遵循 `AGENTS.md > Language Discipline`。代码 / 路径 / 工程术语 / SQL 关键字保留英文，其它散文用中文。
- 优先读 task 文件，把 Acceptance Criteria 抄到草稿头部对着写。
- 读 plan.md 时只读 task 引用的章节（如 §2.3）。
- 不读 context.md 全文，只用 Repo Map / Current State 段。
- 写代码前先列改动清单（哪些函数、哪些行），减少返工。
- 测试代码与实现代码一起提交，不要分两轮。

## 输出

```markdown
# Draft Implementation: <task>

## Acceptance Criteria self-check

| # | Criterion (短句) | 状态 | 证据 (文件/行/测试名) |
| - | --- | --- | --- |
| 1 | ... | ✓ | ... |
| 2 | ... | △ | TODO(codex-review): ... |

## Files changed

- `<path>: +<add>/-<del>` 一句话说明

## Test commands run

```
<原始命令>
```

## Test output (头尾片段，不要整篇贴)

```
<前 20 行 + ... + 后 20 行>
```

## TODO(codex-review) 列表

- (≤ 2 条；超过请停下回退)

## Self-review notes

- 哪些边界条件已处理
- 哪些边界条件用 TODO 标了
- 哪些 Non-goals 主动避开了

## Patch artefact 完整性核对

- staged 文件数: <n>
- patch grep -c "^diff --git": <n>
- 一致: yes/no
```

artefacts:

- `<DEVOPS_PATH>/.ai/logs/<task>.draft.patch`
- `<DEVOPS_PATH>/.ai/logs/<task>.test.log`
- `<DEVOPS_PATH>/.ai/progress.md` 追加一段「draft submitted, awaiting Codex audit」。

## 收尾必做

### Token 消耗记录

汇报末尾追加：

```
Tokens: in=<n> out=<n> total=<n>
```

### 下一步提示词 + 刷新 state.md

汇报最末追加 `## 下一步提示词` 段落，**并把同一份 prompt 覆盖写入 `.ai/state.md`**（详见 AGENTS.md > Session State Discipline）。两件事缺一不可。

#### state.md 覆盖前必读（Dogfood #19 强约束）

**覆盖写入 state.md 前必须先 Read 前一版**——这是 Pattern A 「Agent 不读 state.md」的**轻量例外**。原因：state.md 含若干跨 step 不变的 **invariant 字段**，Agent 不知道前一版值就会胡填（曾 4 次发生「起始时间」字段被错填为当前 step 开工时间，OC / Codex / Claude 都犯过——证明这是 Pattern A 设计副作用，不是 Agent 执行力问题）。

**必须从前一版完整复制（不变）**：

| invariant 字段 | 含义 |
| --- | --- |
| `Active task.起始时间` | task 第一次启动那一刻；**禁止改成当前 step 时间** |
| `Active task.当前 task` 路径 | 同一 task 跨 step 不变 |
| `Notes` 中的历史 commit hash 引用 | 累积记录，保留前一版后**按需追加**，不覆盖 |
| `Notes` 中的 ADR / Epic / Phase 上下文 | 同上 |

**每次 step 都更新（覆盖）**：

- `Active task.当前阶段`
- `Last completed step.*`（全部子字段：Agent / Step / 完成时间 / Commit / 产出）
- `Next step.*`（全部子字段）
- `Blockers`（按当前实际情况重写）

违反此约束 → state.md invariant 字段被破坏 → 下次 session 接力时**没有可靠时间锚点 / commit 历史 / 任务身份**。

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

- 通常下一步是 Codex 审校（`08-codex-audit.md`）。
- 输出**完整可粘贴**的审校 prompt（代码块），路径已填好（task / draft.patch / test.log）。
- 在 prompt 里强调本次审校重点（参考 task `Review checklist`）。
- 若你已标 ≥ 2 条 TODO 或 patch 完整性自检失败：**不**输出审校 prompt，改输出「回退给人或 Claude」的 prompt 并说明原因。
