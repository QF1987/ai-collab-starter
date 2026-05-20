# Starter Kit Structure

> 目录布局速查 + 每个文件用途一句话。
> 想了解某个文件的详细约束，进去看顶部说明 / 引用的 AGENTS.md 段。

```
ai-collab-starter/
├── README.md                 ← 入口文档：是什么、何时用、何时不用
├── STRUCTURE.md              ← 本文件
├── AGENTS.md                 ← 中央纪律：Agent 角色 / 文档卫生 / state 协议 / 语言纪律 / Known Sharp Edges
├── .ai/
│   ├── workflow.md           ← 7 步法（Requirement → Analysis → Architecture → Implementation → Review → Fix → Merge）
│   ├── token-strategy.md     ← Token 预算原则
│   ├── getting-started.md    ← 三类入口：新项目 bootstrap / 新需求按规模路由 / Bug 处理流程
│   ├── intake-templates.md   ← intake skill 问题库（探索式 + 问答式两套）
│   ├── state.md              ← Session 当前快照（覆盖式，每 Agent 必刷）
│   ├── decisions.md          ← ADR 决策记录（追加式）
│   ├── progress.md           ← 进度流水账（追加式）
│   ├── review.md             ← Review findings（P0-P3）
│   ├── context.md.template   ← 项目身份 + Repo Map + Current State（bootstrap 后改名 context.md）
│   ├── architecture.md.template ← 架构原则 + 边界 + 评审触发条件（bootstrap 后改名）
│   ├── plan.md.template      ← Active Epics + Planning Rules（bootstrap 后改名）
│   ├── prompts/
│   │   ├── 01-context.md   ← Helper 摸排 packet
│   │   ├── 02-claude-plan.md        ← Claude 架构决策 + 切片
│   │   ├── 03-lead-orchestrate.md    ← Lead 直接实施
│   │   ├── 04-review.md    ← Reviewer review
│   │   ├── 05-claude-review.md      ← Claude 关键评审
│   │   ├── 06-lead-fix.md          ← Lead 修复已批准 finding
│   │   ├── 07-draft.md     ← Impl 草稿实施（Lead 后续审校）
│   │   └── 08-lead-audit.md        ← Lead 审校 Impl 草稿（PASS/PATCH/REJECT）
│   ├── tasks/                ← 单个任务文件（一 task 一 PR）
│   ├── logs/                 ← Agent 中间产出（context packet / draft.patch / test.log）
│   ├── archive/              ← progress.md 旧段归档
│   ├── cache/                ← 各 Agent 自用临时数据
│   └── tmp/                  ← 真临时
├── .claude/
│   └── skills/
│       └── intake/
│           └── SKILL.md      ← /intake skill（Claude Code 触发）
└── scripts/
    ├── init-collab.sh        ← bootstrap：把 starter 复制到目标项目（仅 starter kit 内有用）
    └── archive-progress.sh   ← 把 progress.md 旧段按月归档到 archive/
```

## 关键文件用途速查（按重要度）

### 必读三件（任何 Agent 开始工作前）

| 文件 | 一句话 |
| --- | --- |
| `AGENTS.md` | 角色契约 + 全套纪律 |
| `.ai/context.md` | 项目当前状态快照 |
| `.ai/state.md` | 上一步 Agent 给你的接力 baton |

### 流程入口（按规模路由）

| 文件 | 用途 |
| --- | --- |
| `.ai/getting-started.md` | 新项目 / 新需求 / bug 三类入口的总指南 |
| `.claude/skills/intake/SKILL.md` | `/intake` skill 触发：探索式 / 问答式两套问答 |
| `.ai/intake-templates.md` | intake 问题库 + 产出模板（Helper / Lead 也能直接读） |

### Prompt 体系（按角色分）

8 个 prompt 模板（`.ai/prompts/`）覆盖三 Agent × 多阶段：

| Agent | Prompt | 阶段 |
| --- | --- | --- |
| Helper | 01 | 摸排（产 context packet） |
| Claude | 02 | 架构决策 + 切片（产 ADR + task 文件） |
| Lead | 03 | 直接实施 |
| Reviewer | 04 | 低成本 review |
| Claude | 05 | 关键评审（升级路径） |
| Lead | 06 | 修复已批准 finding |
| Impl | 07 | 草稿实施（替代 03 的省钱版） |
| Lead | 08 | 审校 Impl 草稿（PASS/PATCH/REJECT） |

### 文档卫生（追加 vs 覆盖）

| 文件 | 维护方式 | 说明 |
| --- | --- | --- |
| `.ai/state.md` | **覆盖** | 当前快照，旧版进 progress.md |
| `.ai/progress.md` | **追加** | 流水账。500 行后跑 `archive-progress.sh` |
| `.ai/decisions.md` | **追加** | 旧 ADR 不删，标 `superseded` |
| `.ai/review.md` | **追加** | Finding 状态用 `Status:` 字段流转 |
| `.ai/context.md` | **覆盖** | 状态翻转必有 commit hash（见 AGENTS.md Sharp Edges） |
| `.ai/architecture.md` | 偶尔改 | 大改要 ADR 配套 |
| `.ai/plan.md` | 偶尔改 | 新 epic 开始时由 Claude 添加 |

### Bootstrap 后才有的文件

下列文件在 bootstrap 之前是 `.template` 后缀，bootstrap 时由 Claude 填充内容后由人改名：

- `.ai/context.md.template` → `.ai/context.md`
- `.ai/architecture.md.template` → `.ai/architecture.md`
- `.ai/plan.md.template` → `.ai/plan.md`

`AGENTS.md` 自带占位符 `<PROJECT_NAME>` / `<REPO_PATH>` / `<TBD>` 等——bootstrap 时由 Claude 或 `init-collab.sh` 替换。

## 单一来源原则

某些约束跨多个文件，**单一来源**在 `AGENTS.md`：

| 约束 | 单一来源 | 引用方 |
| --- | --- | --- |
| Session State Discipline（state.md 协议） | `AGENTS.md` | 8 prompts 末段 + `state.md` 头注释 + SKILL.md Step 3 |
| Language Discipline（中文优先） | `AGENTS.md` | 8 prompts Token 策略段 |
| Commit 阻塞规则 | `AGENTS.md` | `04-review.md` |
| 状态翻转必有 commit hash | `AGENTS.md` Known Sharp Edges | `04-review.md` 文档状态翻转检查段 |
| 数据契约约束分三级 | `02-claude-plan.md` Compatibility 段 | ADR 范例 |
| 「下一步提示词」4 字段格式 | 8 prompts 末段（统一） | SKILL.md Step 3 + `state.md` Next step 段 |

修改任一约束时，**所有引用方必须同步更新**——否则 Agent 行为会漂移。

## 不要碰 / 不要 commit 的文件

每个新项目 `.gitignore` 应至少含：

```
.ai/cache/
.ai/tmp/
.ai/logs/    # 看团队偏好；如要追溯保留则去掉此行
```

`.claude/` 通常**不**进版本控制（每人本地 Claude Code 配置）。

`AGENTS.md` 进版本控制（项目级共享）。
