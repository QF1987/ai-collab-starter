# <PROJECT_NAME> Agent Guide (lite v0.1.0)

本文件是 `<PROJECT_NAME>` 长期 AI 协同研发规范。所有 Agent 在开始工作前必须先读取本文件,再读取 `.ai/README.md`(如有)、`.ai/context.md`、`.ai/plan.md`、`.ai/progress.md`、`.ai/decisions.md` 中与任务相关的最小上下文。

> **新项目 bootstrap 后必须填**:本文件含 `<PROJECT_NAME>` / `<COLLAB_ROOT>` / `<REPO_*>` / `<TBD>` 等占位符。详见 `.ai/getting-started.md` §1。

## 0 · lite vs main(读前提)

| 维度 | main | **lite** |
|------|------|----------|
| Agent 角色 | Claude(架构) + Codex(实施) + OpenCode(审) | **Lead(架构+拆任务+验收) + Impl(写) + Reviewer(审) + Helper(信息查询) + Human(bus)** |
| 02-plan owner | Claude | **Lead** |
| 写代码 | Codex | **Impl** |
| 实施者是否做架构 | 否(Claude 架构) | **Lead 不写代码 / 03 期间不写,例外见下文 "Lead 临时写代码"** |
| Escalation 接收方 | Claude main session | **Human** |
| 终端数(per epic) | 2-3 | **4** (Lead + 3 worker) |
| 跨 Agent 通信 | 无 | **Human 当 bus + `.ai/scratch/oc-helper/` 文件总线** |

**lite 设计哲学**: "无协议, 文件即真相, Human 当触发器"——不引入任何跨 Agent 通信协议。

## Project

本文件使用 `$COLLAB_ROOT` 表示 AI 协同工作目录(含 `.ai/`、`AGENTS.md` 等),`$REPO_*` 表示业务代码仓库。Agent 应优先读取这些环境变量;若未设置,回退到默认绝对路径(见下表 Default path 列)。

`$COLLAB_ROOT` 可以与业务源码仓库**同目录**(单仓项目)或**独立目录**(多仓项目的统一工作入口)。

业务代码仓库:

| Role | Env var / Default path |
| --- | --- |
| 协同工作目录 | `$COLLAB_ROOT`, default `<COLLAB_ROOT>` |
| 主仓 / 单仓项目 | `$REPO_MAIN`, default `<REPO_PATH>` |
| <若多仓,按需扩展> | `$REPO_X`, default `<REPO_X_PATH>` |

> bootstrap 后请删除不适用的行,按实际仓库数量填表。

## Technology Stack

<TECH_STACK 待 bootstrap 时填,参考以下结构>

- 主要语言: <例如 Go / Python / TypeScript / Rust>
- 主要框架 / 运行时: <例如 Node.js / FastAPI / gRPC / protobuf>
- 数据存储: <例如 PostgreSQL / Redis / SQLite>
- 客户端 / 端侧(如有): <例如 C++ / Kotlin / Swift>
- 业务领域: <一两句话描述领域>
- 邻接模块(可选): <CI/CD 脚本 / 监控 / 部署工具 等>

## Context Files

- `.ai/context.md`: stable project context and repo map.
- `.ai/architecture.md`: architecture boundaries and protocol ownership.
- `.ai/plan.md`: current plan and task decomposition.
- `.ai/progress.md`: latest execution status.
- `.ai/review.md`: review findings and fix status.
- `.ai/decisions.md`: architecture and process decisions.
- `.ai/workflow.md`: end-to-end collaboration workflow(lite 4 终端版)。
- `.ai/oc-code-quality-rubric.md`: Lead 03c 验收 Impl 产出的打分表(lite 专属)。
- `.ai/token-strategy.md`: token and context control rules.
- `.ai/getting-started.md`: 新项目 / 新需求 / bug 处理的入口指南(含 4 终端开法)。
- `.ai/intake-templates.md`: intake skill 问题库与产出模板。
- `.ai/lite-upgrade-protocol.md`: lite 自演化升级仪式(Human 主导)。
- `.ai/tasks/`: one task file per feature, bug, refactor or review.
- `.ai/prompts/`: copy-ready prompts(02 / 03 / 03b / 04 / oc-helper)。
- `.ai/scratch/oc-helper/`: Lead ↔ Helper 共享文件总线(gitignored,临时)。

## Build / Test Commands

> 按项目实际技术栈填,bootstrap 时删除不适用部分。沿用 main 表(略,详见原 starter 文档结构)。

## Architecture Boundary

> bootstrap 后填本节描述系统主要边界(API / 协议 / 数据契约)。

`<ARCHITECTURE_BOUNDARY 待 bootstrap 时填>`

## Agent Responsibilities (lite v0.1.0)

### Lead (lead engineer · T1)

- **职责**: 02 plan(架构 + 决策)+ 03a 拆任务 + 03c 验收 + 调度其他 Agent。
- **不写业务代码**(例外: 3 轮 verify fail 后 Human 走 (a) 临时授权)。
- 必须 force 出 `02-lead-plan.md` 强约束 7 条(alternatives ≥ 2 / pre-decisions ≥ 3 / Delegation candidates 等)。
- 全仓搜索(无 path 限制)走 Helper,有限范围 Lead 自己。
- 验收用 `.ai/oc-code-quality-rubric.md`,门槛 ≥ 16/24。
- 第 3 轮 verify 仍 fail → 升 Human 决策,**不**自作主张接手。

### Impl (写代码主力 · T3)

- **职责**: 按 Lead 03a 子任务包写代码,产出 git working tree diff。
- 严格按子任务包执行,不越界。
- 严禁翻案 brief frontmatter 的 pre-decisions。
- 单文件 diff > 200 行 → 停下来问。
- 完成后输出 "done, 见 git diff",**不**自己总结(让 Lead 看 diff)。

### Reviewer (独立审 · T4)

- **职责**: 04 三步法 + Lead 自审盲点专项检查。
- **必须**与 Impl 不同 session(强制隔离防自审盲点)。
- 严重 finding → escalate 给 Human,**不**给 Lead(避免 Lead 自审 Reviewer 的产出)。

### Helper (信息查询 · T2,按需启动)

- **职责**: 全仓 grep / scan / summarize,结果写共享文件。
- 不动业务代码(只读全仓 + 写 `.ai/scratch/oc-helper/out-*.md`)。
- 触发: Lead 写 `req-*.md` 给指令,Human 切到 T2 让 Helper 跑 → Helper 写 out → Human 回 T1。

### Human (message bus + decision gate)

- 4 终端切换、prompt 复制粘贴。
- escalation 接收方(scope deviation / 架构敏感 / 3 轮 verify fail / 安全)。
- merge gate。
- epic 结束清空 `.ai/scratch/`(可选)。

### Scope Heuristics (lite)

- 改动 <= 20 行 且 不跨模块 且 不涉及协议/接口 → Lead 可在 02 brief 中标 `human-direct: true`,Human 直接改不走 03 三段式。
- 改动 > 20 行 或 跨模块 或 涉及协议/接口 → 标准 03 三段式(03a → 03b → 03c → 04)。
- 纯格式化、依赖升级、机械性重命名 → 直接交 Impl,不消耗 Lead 验收槽。
- "broad refactor"(Impl 禁止)定义: 跨 >= 3 个文件 或 跨模块边界 或 修改公共函数签名。

### Lead 临时写代码(例外路径)

03b ↔ 03c 走满 3 轮 verify 仍 fail → Human 决策三选(详见 `.ai/workflow.md §3c`):

- **(a) Lead 接手**: 此时 Lead 临时获得**本子任务包范围内**的写代码权限,改完 state.md 标注 `human-override-lead-fix`。
- (b) Impl 再试第 4 轮(Human 给 Impl 新 hint)
- (c) 回到 02 重新拆任务

例外路径必须在 progress.md 记一笔,月度统计触发频次(频繁触发 = 子任务包颗粒度或 rubric 门槛该调)。

## Code Style

- Follow the style already used in the target repo and module.
- Keep changes minimal, cohesive and module-local.
- Do not introduce a new framework, package manager, build system or abstraction without an architecture decision in `.ai/decisions.md`.
- For protocol and API changes, update provider, consumer, generated code, tests and docs together.
- Prefer explicit errors, typed data structures, stable logs and deterministic tests.

## Context Control

- Start with `.ai` files before scanning source.
- Do not run unbounded full-repo scans unless the task explicitly requires it(此时走 Helper)。
- Use targeted searches by symbol, path, package, service name or error text.
- Read only files needed for the current task plus direct callers/callees.
- One Agent turn should normally edit no more than one module or a small set of directly coupled files.
- Large work must be split into task files under `.ai/tasks/`.

## Token Saving Principles

- File stable knowledge in `.ai` instead of repeating it in prompts.
- Prefer summaries and file references over pasting large source blocks.
- Use Helper for cheap full-repo context collection before Lead 02.
- Use Lead 02 only after the problem has a narrow question, decision point or risk list.
- Use Impl with bounded file paths, commands and acceptance criteria(子任务包)。
- End long conversations by writing a new `.ai/tasks/<task>.md` handoff.

## Review Rules

- Every non-trivial change requires review.
- Reviewer focuses on three-step method: scope / architecture+pre-decisions / quality + Lead 自审盲点专项。
- Human handles escalation(architecture risk, protocol compatibility, security, rollback, long-term maintainability)。
- Impl fixes only approved findings and reruns targeted tests.
- Review findings must be written to `.ai/review.md` or the relevant task file.
- Review 发现必须标记优先级 `P0`/`P1`/`P2`/`P3`,定义见 `.ai/review.md > Severity`。
- 每条 finding 需指定 owner 和 reporter,状态为 open | accepted | in-progress | fixed | verified | rejected | deferred。
- 修复完成后由原 review 提出方做 verify。P0/P1 未 verified 不得合并。
- 状态流转记录在 `.ai/review.md` 同一条目下。

## Architecture Approval

Lead 02-plan 必须落到唯一具体选择(参考 `.ai/prompts/02-lead-plan.md` 强约束)。

Impl 在以下情况之后才能实施:

- `.ai/decisions.md` 中已写入对应 ADR 且状态为 accepted(若任务需 ADR)
- task brief frontmatter 锁了 ≥ 3 条 pre-decisions
- Lead 03a 输出了完整的 Impl 子任务包

## Git Commit Rules

- Use small commits grouped by task and repo.
- Commit messages should state scope and behavior, for example `<repo-name>: fix release status retry`.
- Do not mix unrelated changes across modules / repos / docs / formatting.
- Before committing, record changed files, tests and known risks in `.ai/progress.md`.
- Never commit secrets, local machine paths, generated caches, `.ai/cache/`, `.ai/tmp/`, `.ai/scratch/` or `.ai/logs/`(看团队偏好)。

## Prohibited Actions

### Code & Repo Scope

- Do not modify business code from this collaboration context unless the task explicitly targets a real repo.
- Do not scan the entire monorepo repeatedly(走 Helper)。
- Do not merge generated summaries into source files unless requested.

### Agent Role Violations

- Do not let Lead perform bulk coding during 03(03 三段式之外的 commit 必须有 Human override 记录)。
- Do not let Impl redesign the whole system or翻案 pre-decisions。
- Do not let Reviewer and Impl share session(强制隔离)。

### Destructive / Irreversible

- Do not change protocol contracts (proto / OpenAPI / GraphQL schema) on one side only.
- Do not rewrite history, reset branches, delete user work or run destructive commands without explicit Human approval.

## Known Sharp Edges

> 本节记录本项目反复踩过的坑。新 Agent 进入前必读。新踩到的坑由发现的 Agent 追加。
>
> bootstrap 后此段几乎为空——随着项目跑通几个真实任务后由 Lead / worker 主动追加。

### 通用 sharp edges(lite 起步留底)

#### 状态翻转必须有 commit hash 作证

- `.ai/context.md` 中任何状态从 ❌/❓ 改为 ✅,**证据列必须含具体 commit hash**。
- working-tree-only 的预提交标记必须明确写「working tree on `<base-commit>`」并附 patch 路径,**不**直接标 ✅。
- 翻转前必须 `cd <repo> && git rev-parse --verify <hash>` 验证 hash 真实存在。
- 校验责任在 Reviewer (`04-review.md > 文档状态翻转检查`)。

#### Patch artefact 完整性

- Impl / Lead(临时) 产出 `*.draft.patch` 时,必须:

  ```bash
  git add <子任务包 paths 内 modified + new 全部文件>
  git diff --cached HEAD > <out.patch>
  grep -c "^diff --git" <out.patch>   # 必须等于实际改动文件数
  git apply --check <out.patch>
  ```

#### Impl Scope 越界 pre-check

- Impl 实施前**必须**跑 `git diff --cached --stat`,逐行核对每个文件路径都在子任务包 paths 内。
- 出现范围外文件 → 立即停下回退,不要先跑测试再说。
- 越界检测责任在 Impl,审校方(Lead 03c + Reviewer 04)兜底。

#### Reviewer 与 Impl 共谋盲点(lite 特有)

- 因都是 worker(同模型 / 相似训练数据),**必须**强制 session 隔离。
- 同时 Lead 03c 已经先过一遍,Reviewer 独立 cross-check。
- Reviewer 三步法新增「Lead 自审盲点专项」checklist 兜底。

## Document State Hygiene

- `.ai/context.md` 是当前快照,必须与真实 commit 对齐。
- `.ai/progress.md` 是流水账,单调追加。超过 ~500 行后跑 `scripts/archive-progress.sh` 归档旧段落到 `.ai/archive/YYYY-MM.md`。
- `.ai/state.md` 是当前 session 的活跃任务快照,每个 Agent 完成必须刷新(覆盖式)。Human 切终端前先读这里。
- `.ai/decisions.md` 单调追加,旧 ADR 不删除(标 superseded)。

## Session State Discipline

> 谁刷 `.ai/state.md`,何时刷,怎么验证。

### 主路径:Agent 自刷

每个 Agent 在自己会话的**最后一步**必须做这两件事,缺一不可:

1. 在汇报中输出 `## 下一步提示词` 段落(给 Human 当下复制粘贴用)。
2. **把同一份 prompt 覆盖写入 `.ai/state.md`**——不是 append,是覆盖。

state.md 字段更新规则:

| 字段 | 谁填 | 内容来源 |
| --- | --- | --- |
| `Active task` | 当前 Agent | 从输入 task 文件抄路径 |
| `Active task.起始时间` | 当前 Agent | **task 第一次启动的时间**(intake 完成那一刻)。**跨 step 不变** |
| `当前 epic 终端布局` | 当前 Agent | 4 终端各自的当前 session 描述(可写 `空闲` / `已退出`) |
| `Last completed step` | 当前 Agent | 描述自己刚做完的 step |
| `Last completed step.完成时间` | 当前 Agent | 当前 step 完成时间(每 step 刷新) |
| `Last completed step.Commit` | 当前 Agent | 本步骤改动的 git commit hash;如未 commit 必须标 `⚠️ WORKING TREE — not committed` |
| `Next step` | 当前 Agent | 把"下一步提示词"原文复制进 `Next step.可粘贴 prompt` 字段 |
| `Blockers` | 当前 Agent | 已知阻塞,不写「无」就是没有 |
| `Notes` | 当前 Agent | 给下个 Agent / 下个 session 的备忘 |

任务整体完成时:Active task / Last completed step / Next step 全清空,仅保留 Notes。

### Commit 阻塞规则

`Last completed step.Commit` 字段是合规观测点:

- 标 `⚠️ WORKING TREE — not committed` → **下一个 session 第一件事必须先 commit**,不允许继续新 step
- 多 slice 任务连续 working tree 累积会让 git history 混乱、revert 风险陡升
- `04-review.md` 把此字段作为 review 通过门槛
- 例外:调研类步骤(Helper packet / Lead ADR / 文档收口)不产代码改动时可标 `n/a`

### Fallback:Human 手刷(兜底)

仅当 Agent 忘记 / harness 不允许写文件时启用:

- Human 从 Agent 输出的 `## 下一步提示词` 段复制 prompt 内容
- 手动覆盖 `.ai/state.md`
- 在 `.ai/progress.md` 追加一行「state.md 由 Human 手刷(Agent X 未刷)」标记

### 入会话时的检查(Human)

下一次开 session 第一件事:读 `.ai/state.md`。

- `Last completed step.Commit` 标 `⚠️ WORKING TREE` → **先 commit 再启动任何新 step**
- `Last completed step.完成时间` 距今 > 1 周 → 警告:state 可能过期
- `Next step.Agent` 是 `Human` → 你(Human)就是下一步执行者(escalation gate)
- `Blockers` 非空 → 先解决阻塞再启动新步骤
- `Active task` 与 `Next step.Agent` 不匹配 → state 不一致,回退查证

## Language Discipline

> 所有 Agent 自然语言输出必须中文优先,避免 worker 国产模型自然倾向英文输出的失控。lite 中 3/4 Agent 是 worker,纪律尤其重要。

### 默认中文的范围

- 所有描述、解释、推理、汇报、回顾、风险说明
- 文档段落(markdown 内的散文)
- Agent 对话框中的过程输出与最终结论
- task 文件 / ADR / progress / review 各类 `.ai/*` 文档的 prose 段

### 允许保留英文的例外(5+1 类)

1. **代码 / 命令 / 配置片段**——shell、SQL、JSON、YAML、protobuf 等所有 code block 内容
2. **文件路径 / git hash / package 名 / API 字段名**——`internal/store/example.go`、`33e781c`、`@anthropic-ai/sdk`、`Request.field_name` 等
3. **工程惯例术语**——ADR / PR / enum / proto / verdict / PASS / PATCH / REJECT / scope / commit / slice 等
4. **测试结果格式化输出**——`PASS` / `FAIL` / `4/4 cases passed`
5. **引用源代码 / 命令原始输出**——log 片段、stack trace、命令 stdout
6. **DB SQL 关键字**——SELECT / WHERE / GROUP BY / JOIN / INTERVAL

### 不允许的反例

- ❌ 用英文写决策理由:`Cancellation timestamp reuses FailedAt because migration cost outweighs benefit.`
- ✅ 改为:`取消时间戳复用 FailedAt 字段——DB migration 成本大于收益。`

### Agent 自检方法

输出汇报前快速过一眼:

- 散文段落(不在 code block 内)是否中文?
- 工程术语是否在允许英文清单内?

不符合就重写。这条纪律对 worker 国产模型尤其重要——worker 训练数据倾向英文 markdown,必须显式压回中文。

### 国产模型实战覆盖 (v0.6 · F02-v0.6)

lite framework 所有 Agent (Lead / Helper / Impl / Reviewer) 的 **chat 输出 + scratch / state.md / progress.md / brief / review.md 等元数据 prose 段默认中文**。

国产模型 (Kimi / Qwen / Doubao 等) 实战可能仍默认英文输出 (训练数据倾向)。处置:

- 各 worker prompt (`helper.md` / `03b-impl.md` / `04-review.md`) 输出格式段已加中文硬约束 (v0.6 · F02-v0.6)。
- 若实战仍发现英文 chat, Human 喂 prompt 时显式加一句临时覆盖: `⚠️ chat 输出请用中文`。
- 唯一允许英文 chat 的场景: Helper req `action.language: en` 显式声明 (跨语言协作 / 国际化 review)。
