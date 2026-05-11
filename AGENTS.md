# <PROJECT_NAME> Agent Guide

本文件是 `<PROJECT_NAME>` 长期 AI 协同研发规范。所有 Agent 在开始工作前必须先读取本文件，再读取 `.ai/README.md`（如有）、`.ai/context.md`、`.ai/plan.md`、`.ai/progress.md`、`.ai/decisions.md` 中与任务相关的最小上下文。

> **新项目 bootstrap 后必须填**：本文件含 `<PROJECT_NAME>` / `<COLLAB_ROOT>` / `<REPO_*>` / `<TBD>` 等占位符。详见 `.ai/getting-started.md` §1。

## Project

本文件使用 `$COLLAB_ROOT` 表示 AI 协同工作目录（含 `.ai/`、`AGENTS.md` 等），`$REPO_*` 表示业务代码仓库。Agent 应优先读取这些环境变量；若未设置，回退到默认绝对路径（见下表 Default path 列）。

`$COLLAB_ROOT` 可以与业务源码仓库**同目录**（单仓项目）或**独立目录**（多仓项目的统一工作入口）。

业务代码仓库：

| Role | Env var / Default path |
| --- | --- |
| 协同工作目录 | `$COLLAB_ROOT`, default `<COLLAB_ROOT>` |
| 主仓 / 单仓项目 | `$REPO_MAIN`, default `<REPO_PATH>` |
| <若多仓，按需扩展> | `$REPO_X`, default `<REPO_X_PATH>` |

> bootstrap 后请删除不适用的行，按实际仓库数量填表。

## Technology Stack

<TECH_STACK 待 bootstrap 时填，参考以下结构>

- 主要语言: <例如 Go / Python / TypeScript / Rust>
- 主要框架 / 运行时: <例如 Node.js / FastAPI / gRPC / protobuf>
- 数据存储: <例如 PostgreSQL / Redis / SQLite>
- 客户端 / 端侧（如有）: <例如 C++ / Kotlin / Swift>
- 业务领域: <一两句话描述领域>
- 邻接模块（可选）: <CI/CD 脚本 / 监控 / 部署工具 等>

## Context Files

- `.ai/context.md`: stable project context and repo map.
- `.ai/architecture.md`: architecture boundaries and protocol ownership.
- `.ai/plan.md`: current plan and task decomposition.
- `.ai/progress.md`: latest execution status.
- `.ai/review.md`: review findings and fix status.
- `.ai/decisions.md`: architecture and process decisions.
- `.ai/workflow.md`: end-to-end collaboration workflow between OpenCode, Claude Code and Codex.
- `.ai/token-strategy.md`: token and context control rules.
- `.ai/getting-started.md`: 新项目 / 新需求 / bug 处理的入口指南。
- `.ai/intake-templates.md`: intake skill 问题库与产出模板（探索式 + 问答式）。
- `.ai/tasks/`: one task file per feature, bug, refactor or review.
- `.ai/prompts/`: copy-ready prompts for OpenCode, Claude Code and Codex.

## Build Commands

> 按项目实际技术栈填。下面 3 种是常见示例，bootstrap 时删除不适用部分。

Go 项目示例：

```bash
cd "$REPO_MAIN"
go test ./...
go build ./...
```

Python 项目示例：

```bash
cd "$REPO_MAIN"
pytest
python -m build  # 如需 wheel
```

TypeScript / Node 项目示例：

```bash
cd "$REPO_MAIN"
npm test
npm run build
```

命令来源优先级（从高到低）：

1. 仓库内 Makefile / `justfile` 中的目标
2. `package.json` scripts、`Cargo.toml` aliases、`build.gradle` 自定义 task
3. 仓库根目录 README 或 `docs/` 中的构建说明
4. CI 配置（`.github/workflows/*.yml`、`.gitlab-ci.yml`）
5. 本文件 Build Commands 默认值

若 1-4 与本文件冲突，以仓库内来源为准，并把实际使用的命令记录到 `.ai/progress.md`。

## Test Commands

- Go: `go test ./...`
- TypeScript / Node: `npm test`, targeted package tests when available.
- Python: `pytest`, targeted test files when available.
- C++: CMake/CTest or the repo's existing test target.
- Rust: `cargo test`.
- <添加本项目特定测试 runner，如有>

协议 / API 变更：regenerate generated artifacts in every affected repo, then run targeted compile/tests on every side.

## Architecture Boundary

> bootstrap 后填本节描述系统主要边界（API / 协议 / 数据契约）。

`<ARCHITECTURE_BOUNDARY 待 bootstrap 时填，参考以下示例>`

示例（gRPC 系统）：

> 主边界是 gRPC：
> - `XxxService`: 端侧上报 heartbeat / status / event。
> - `YyyService`: 管理端推送命令。

示例（REST API 系统）：

> 主边界是 REST API：
> - `POST /api/v1/...`：客户端上报数据。
> - `GET /api/v1/...`：客户端拉取配置。

## Agent Responsibilities

OpenCode plus domestic models:

- Scan scoped code, summarize context, generate docs and produce low-cost review notes.
- Prefer file lists, symbol maps, module summaries and risk checklists over long prose.
- Do not perform broad refactors or large implementation changes.

Claude Code:

- Own architecture design, complex root-cause analysis, high-risk review and trade-off evaluation.
- Must consume OpenCode summaries and `.ai/*` context before reading source.
- Must not spend tokens on repetitive coding, formatting or mechanical test repair.

Codex:

- Own implementation, test repair, build wiring, scripts, CI-compatible engineering details and final verification.
- Must implement only the approved scoped task.
- Must not invent the overall architecture when a Claude decision is required.

### Scope Heuristics

- 改动 <= 20 行 且 不跨模块 且 不涉及协议/接口 -> Claude Code 可直接修改。
- 改动 > 20 行 或 跨模块 或 涉及协议/接口 -> Claude Code 输出方案与 diff 描述，交 Codex 实施。
- 纯格式化、依赖升级、机械性重命名 -> 直接交 Codex，不消耗 Claude。
- "broad refactor"（OpenCode 禁止）定义为：跨 >= 3 个文件 或 跨模块边界 或 修改公共函数签名。

## Code Style

- Follow the style already used in the target repo and module.
- Keep changes minimal, cohesive and module-local.
- Do not introduce a new framework, package manager, build system or abstraction without an architecture decision in `.ai/decisions.md`.
- For protocol and API changes, update provider, consumer, generated code, tests and docs together.
- Prefer explicit errors, typed data structures, stable logs and deterministic tests.

## Context Control

- Start with `.ai` files before scanning source.
- Do not run unbounded full-repo scans unless the task explicitly requires it.
- Use targeted searches by symbol, path, package, service name or error text.
- Read only files needed for the current task plus direct callers/callees.
- One Agent turn should normally edit no more than one module or a small set of directly coupled files.
- Large work must be split into task files under `.ai/tasks/`.

## Token Saving Principles

- File stable knowledge in `.ai` instead of repeating it in prompts.
- Prefer summaries and file references over pasting large source blocks.
- Use OpenCode for cheap context collection before Claude review.
- Use Claude only after the problem has a narrow question, decision point or risk list.
- Use Codex with bounded file paths, commands and acceptance criteria.
- End long conversations by writing a new `.ai/tasks/<task>.md` handoff.

## Review Rules

- Every non-trivial change requires review.
- OpenCode review focuses on low-cost scanning: changed files, obvious defects, missing tests, docs drift and style mismatches.
- Claude review focuses on architecture risk, protocol compatibility, security, lifecycle, concurrency, rollback and long-term maintainability.
- Codex fixes only approved findings and reruns targeted tests.
- Review findings must be written to `.ai/review.md` or the relevant task file.
- Review 发现必须标记优先级 `P0`/`P1`/`P2`/`P3`，定义见 `.ai/review.md > Severity`。本文件不重复定义。
- 每条 finding 需指定 owner（修复方）和 reporter（提出方），状态为 open | accepted | in-progress | fixed | verified | rejected | deferred。完整状态语义见 `.ai/review.md`。
- 修复完成后由原 review 提出方做 verify，状态置为 `verified` 才可关闭；P0/P1 未 verified 不得合并。
- 状态流转记录在 `.ai/review.md` 同一条目下，不另开文件。

## Architecture Approval

Claude Code 评审触发条件以 `.ai/architecture.md > Architecture Review Triggers` 为准（如本节存在），本文件不重复列举。

Codex 在以下情况之后才能实施：

- `.ai/decisions.md` 中已写入对应 ADR 且状态为 accepted。
- `.ai/plan.md` 或 `.ai/tasks/<task>.md` 中已对实施范围做切片。

## Git Commit Rules

- Use small commits grouped by task and repo.
- Commit messages should state scope and behavior, for example `<repo-name>: fix release status retry`.
- Do not mix unrelated changes across modules / repos / docs / formatting.
- Before committing, record changed files, tests and known risks in `.ai/progress.md`.
- Never commit secrets, local machine paths that are not already project conventions, generated caches, `.ai/cache/`, `.ai/tmp/` or `.ai/logs/`.

## Prohibited Actions

### Code & Repo Scope

- Do not modify business code from this collaboration context unless the task explicitly targets a real repo.
- Do not scan the entire monorepo repeatedly to compensate for unclear prompts.
- Do not merge generated summaries into source files unless requested.

### Agent Role Violations

- Do not let Claude perform bulk coding.
- Do not let Codex redesign the whole system without an approved architecture note.
- Do not let OpenCode perform direct wide refactors.

### Destructive / Irreversible

- Do not change protocol contracts (proto / OpenAPI / GraphQL schema) on one side only.
- Do not rewrite history, reset branches, delete user work or run destructive commands without explicit approval.

## Known Sharp Edges

> 本节记录本项目反复踩过的坑。新 Agent 进入前必读，避免重新发现同样问题。新踩到的坑由发现的 Agent 追加。
>
> bootstrap 后此段几乎为空——随着项目跑通几个真实任务后由 Claude / Codex / OpenCode 主动追加。前 1-2 个月新坑出现频率高，之后稳定。

### 模板示例（bootstrap 后删除此段，留作格式参考）

```markdown
### <现象一句话>

- 现象：<具体表现 / 错误码 / 反例>
- 根因：<为什么会发生>
- 解决：<如何规避或修复>
- 反面案例：<曾经踩过的具体场景，引用 progress.md 时间戳>
- 校验责任：<哪个 prompt / Agent 负责拦截>
```

### 通用 sharp edges（所有项目共用，不要删除）

#### 状态翻转必须有 commit hash 作证

- `.ai/context.md` 中任何状态从 ❌/❓ 改为 ✅、或 What's Next 表删行，**证据列必须含具体 commit hash**。
- 例外：working-tree-only 的预提交标记必须明确写「working tree on `<base-commit>`」并附 patch 路径，**不**直接标 ✅。
- 翻转前必须 `cd <repo> && git rev-parse --verify <hash>` 验证 hash 真实存在。
- 校验责任在 OpenCode review（`04-opencode-review.md > 文档状态翻转检查`）。

#### Patch artefact 完整性

- OC / Codex 产出 `*.draft.patch` 或 `*.audit-patch.diff` 时，**必须**：

  ```bash
  git add <task Scope 内 modified + new 全部文件>
  git diff --cached HEAD > <out.patch>
  grep -c "^diff --git" <out.patch>   # 必须等于实际改动文件数
  git apply --check <out.patch>       # 或 reverse-apply 验证 working tree
  ```

- 校验责任在产出方（07-opencode-draft / 03-codex-implement），审校方（08-codex-audit）兜底。

#### Agent Scope 越界 pre-check

- OC / Codex 实施前**必须**跑 `git diff --cached --stat`，逐行核对每个文件路径都在 task `Scope.paths` 内。
- 出现范围外文件 → 立即停下回退（unstage / restore），**不**先跑测试再说。
- 越界检测责任在产出方，审校方兜底（08 prompt 第 2 步 Scope check）。

#### `.claude/`、`AGENTS.md`、`CLAUDE.md` 等协同文件不进业务仓

- 这些是 AI 协同框架自身的文件，**不**属于产品代码。
- 真实业务仓 working tree 中出现这些 untracked 文件时，**不要** `git add`——它们应在仓库 `.gitignore` 中。
- 若仓库未忽略，开 P3 finding 让维护者补 `.gitignore`，不要顺手 commit。

## Document State Hygiene

- `.ai/context.md` 是当前快照，必须与真实 commit 对齐。状态翻转纪律见 `Known Sharp Edges > 状态翻转必须有 commit hash 作证`。
- `.ai/progress.md` 是流水账，单调追加。超过 ~500 行后跑 `scripts/archive-progress.sh` 归档旧段落到 `.ai/archive/YYYY-MM.md`。
- `.ai/state.md` 是当前 session 的活跃任务快照，每个 Agent 完成必须刷新（覆盖式）。session 中断后回来先读这里。
- `.ai/decisions.md` 单调追加，旧 ADR 不删除（标 superseded）。

## Session State Discipline

> 谁刷 `.ai/state.md`，何时刷，怎么验证。

### 主路径：Agent 自刷

每个 Agent 在自己会话的**最后一步**必须做这两件事，缺一不可：

1. 在汇报中输出 `## 下一步提示词` 段落（给人当下复制粘贴用）。
2. **把同一份 prompt 覆盖写入 `.ai/state.md`**——不是 append，是覆盖（旧快照已在 progress.md 里）。

state.md 的字段更新规则：

| 字段 | 谁填 | 内容来源 |
| --- | --- | --- |
| `Active task` | 当前 Agent | 从输入 task 文件抄路径 |
| `Last completed step` | 当前 Agent | 描述自己刚做完的 step |
| `Last completed step.Commit` | 当前 Agent | 本步骤改动的 git commit hash；如未 commit 必须标 `⚠️ WORKING TREE — not committed` |
| `Next step` | 当前 Agent | 把「下一步提示词」原文复制进 `Next step.可粘贴 prompt` 字段 |
| `Blockers` | 当前 Agent | 已知阻塞，不写「无」就是没有 |
| `Notes` | 当前 Agent | 给下个 Agent / 下个 session 的备忘；可保留前任 Notes 的相关条目 |

任务整体完成时（merge + 文档收口都做完）：当前 Agent 把 `Active task / Last completed step / Next step` 全清空，仅保留 `Notes` 给下个任务参考。

### Commit 阻塞规则

`Last completed step.Commit` 字段是合规观测点：

- 标 `⚠️ WORKING TREE — not committed` 时——**下一个 session 第一件事必须先 commit**，**不允许**继续启动新 slice 或新 step
- 多 slice 任务连续 working tree 累积会让 git history 混乱、revert 风险陡升
- `04-opencode-review.md` 把此字段作为 review 通过门槛
- 例外：调研类步骤（OC packet / Claude ADR / 文档收口）不产代码改动时可标 `n/a`

### Fallback：人手刷（仅兜底）

仅当 Agent 忘记 / harness 不允许写文件 / 写出错时启用：

- 人从 Agent 输出的 `## 下一步提示词` 段复制 prompt 内容
- 手动覆盖 `.ai/state.md`，按 state.md 顶部说明填字段
- 在 `.ai/progress.md` 追加一行「state.md 由人手刷（Agent X 未刷）」标记

人手刷被触发的次数应当**单调递减**——多次发生说明 prompt 漏写或 Agent 不靠谱，需要回头加强提示。

### 入会话时的检查（人）

下一次开 session 第一件事：读 `.ai/state.md`。

- `Last completed step.Commit` 标 `⚠️ WORKING TREE` → **先 commit 再启动任何新 step**（强约束，见上方 Commit 阻塞规则）
- `Last completed step.Time` 距今 > 1 周 → 警告：state 可能过期，去 progress.md tail 核对
- `Next step.Agent` 是 `Human` → 你（人）就是下一步执行者
- `Blockers` 非空 → 先解决阻塞再启动新步骤
- `Active task` 与 `Next step.Agent` 不匹配 → state 不一致，回退查证

## Language Discipline

> 所有 Agent 自然语言输出必须中文优先，避免 OC 国产模型自然倾向英文输出的失控。

### 默认中文的范围

- 所有描述、解释、推理、汇报、回顾、风险说明
- 文档段落（markdown 内的散文）
- Agent 对话框中的过程输出与最终结论
- task 文件 / ADR / progress / review 各类 `.ai/*` 文档的 prose 段

### 允许保留英文的例外清单（5+1 类）

1. **代码 / 命令 / 配置片段**——shell、SQL、JSON、YAML、protobuf 等所有 code block 内容
2. **文件路径 / git hash / package 名 / API 字段名**——`internal/store/example.go`、`33e781c`、`@anthropic-ai/sdk`、`Request.field_name` 等
3. **工程惯例术语**——ADR / PR / enum / proto / verdict / PASS / PATCH / REJECT / scope / commit / slice 等
4. **测试结果格式化输出**——`PASS` / `FAIL` / `4/4 cases passed` 等惯例 verdict 词
5. **引用源代码 / 命令原始输出**——log 片段、stack trace、命令 stdout 等保持原样
6. **DB SQL 关键字**——SELECT / WHERE / GROUP BY / JOIN / INTERVAL 等保持英文

### 不允许的反例

- ❌ 用英文写决策理由（应中文）：`Cancellation timestamp reuses FailedAt because migration cost outweighs benefit.`
- ✅ 改为：`取消时间戳复用 FailedAt 字段——DB migration 成本大于收益。`
- ❌ 用英文写风险说明：`If the migration fails, rollback is hard.`
- ✅ 改为：`若 migration 失败，rollback 难度高。`

### Agent 自检方法

输出汇报前快速过一眼：

- 散文段落（不在 code block 内）是否中文？
- 工程术语是否在允许英文清单内？
- 测试 verdict 用 PASS/FAIL 即可，描述测试用例时用中文

不符合就重写。这条纪律对 OC 国产模型尤其重要——OC 训练数据倾向英文 markdown，必须显式压回中文。
