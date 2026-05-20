# Getting Started (lite v0.7.0-lite-rc1)

> 入口文档。三类常见情境都能在这里找到答案:
>
> - 新项目第一步(bootstrap)
> - 新需求第一步(按规模路由)
> - Bug 处理流程
>
> 与其他 `.ai/` 文件的区别:
> - `README.md` 解释目录结构 + lite vs main
> - `workflow.md` 解释 7 步法 + 4 终端拓扑
> - `getting-started.md`(本文)解释**怎么开始**
> - `lite-upgrade-protocol.md` 解释 lite 自身怎么升级

---

## 〇 · 任何新 epic 启动前的检查清单 (lite)

任何 epic 开工前,**Human** 必须先跑这套检查(替代 main 的 Claude 主动提醒机制):

```bash
# 1. 看本项目 STARTER_VERSION stamp (若有)
cat .ai/STARTER_VERSION 2>/dev/null || echo "未 stamp, 可能是新 init 项目"

# 2. 看 lite 当前 latest
cat /path/to/ai-collab-starter-lite/VERSION

# 3. 看 inbox 累计 finding
ls .ai/logs/pending-findings/from-*/ 2>/dev/null | wc -l
```

### Human 决策矩阵

| 输出情况 | Human 应当 |
|---------|----------|
| 项目 stamp == lite 最新 + inbox 0 pending | 直接进业务任务 |
| 项目 stamp 落后 + inbox < 5 pending | 评估:要 sync 吗?不急可累积。 |
| inbox ≥ 5 pending | **本周抽 1-2h 跑 `lite-upgrade-protocol.md`** |
| inbox 任一 P0/P1 finding | **立即先做 lite 升级, 业务任务延后** |
| 未 stamp 项目(新 init) | 跑 bootstrap (见 §一) |

**不做检查的风险**: 用过时 lite 处理新任务,重复别人已经发现并解决过的 finding;或在本项目 discover 新 finding 但没 sync 到 lite inbox,跨 session 信息丢失。

### Finding 落档双写约定

任何 session 在 derived 项目 discover lite improvement finding 时:

```bash
# 1. 本地写 finding
$EDITOR .ai/logs/lite-v0.X-finding-NN-<slug>.md

# 2. 同步到 lite inbox (从 lite 仓 cp, 或脚本)
cp .ai/logs/lite-v0.X-finding-NN-<slug>.md \
   /path/to/ai-collab-starter-lite/.ai/logs/pending-findings/from-<project>/
```

**不双写 = 跨 session 信息丢失 = lite 不知道有这条 finding**。

### 通用 finding sync 到 main 候选

若发现的 finding 是 lite/main 通用(非 Claude-specific),Human 在 lite minor release 时:

```bash
cp /path/to/ai-collab-starter-lite/.ai/logs/pending-findings/from-<project>/<finding>.md \
   /path/to/ai-collab-starter/.ai/logs/pending-findings/from-lite-<project>/
```

prefix `from-lite-` 让 main 升级 session 能识别来源。

---

## 一bis · git 拓扑选择 (v0.2.0 · F01)

新项目 bootstrap 前先选 git 拓扑, 决定后续 git 操作 cwd 边界:

### 单仓 (默认场景)
单 `.git`, lite 框架元数据 + 业务代码同仓。沿用 §一 5 步标准 bootstrap。

### umbrella + 子 git (大型多子项目 · e.g. smart-uite)
顶层 `.git` 只追 `.ai/` + `AGENTS.md`, 子目录各自有独立 `.git` (30 个子项目都各自是 git repo)。

**bootstrap 时的 `.gitignore` 白名单方案**:
```gitignore
# umbrella 顶层 .gitignore (白名单模式)
/*
!.ai/
!AGENTS.md
!.gitignore
!.gitattributes
!README.md
```

这样 umbrella 顶层 git 只追 `.ai/` + `AGENTS.md`, 不会把子项目源码累计进 umbrella git index。

**约束**:
- 任何 `git log` / `git diff` / `git blame` 必须 cd 进对应子仓, **不能**在 umbrella 顶层跑
- prompt / req 文件中所有 git 操作都必须显式标 cwd (Lead 写 req 时 `cwd_override: "Daemon"`, Impl 03b Scope 自检在每个改动子仓各跑一次 git diff)
- rubric H2 验证按 git 拓扑分场景跑 (详见 `oc-code-quality-rubric.md > H2`)

#### ⚠️ 后续扩展陷阱 (v0.5 · F05-v0.5)

后续 epic 若改 umbrella 顶层文件 (e.g. `cmake/CMakeLists.txt` / `cmake/StageTdmRuntime.cmake` / `scripts/build.sh` / `Dockerfile` / `interim/scripts/*.ps1`), **必须先扩展 `.gitignore` 白名单**:
```gitignore
# 加进 .gitignore 白名单段:
!/cmake
!/cmake/**
!/interim
!/interim/**
# 若改其它顶层目录, 同样加 !/<dir> + !/<dir>/**
```

**否则**: Impl 改的文件物理存在但**不在 git 追踪** (`git ls-files <path>` 返空), 修了不能 deliver (现场重新 staging 时丢失) — 等价 P0/P1 风险。

**v0.5 强约束机制** (自动 catch):
- Lead 02 plan `§5 Paths 二组分` + `§8 Assumptions to verify`: 必须 verify core paths `git ls-files` 非空
- Lead 03a 子任务包模板: 每条核心 path 必须标"git 追踪状态"
- Reviewer 04 三步法 `第一步 Scope 验证`: 加 `git ls-files <core_path>` check, 返空 → escalate Human
- rubric H2: 加 git 追踪 verify, 返空直接 fail

历史反例 (smart-uite v0.4 stable 第一个 epic `dcbusinessmanager-h5coat-qt5core-missing`): Lead 02 选改 `cmake/StageTdmRuntime.cmake` (顶层 cmake/) 触发本陷阱, Claude audit 才发现, 04 Reviewer 漏 catch → F05-v0.5 finding。

### 跨仓 (lite 仓 + 业务仓物理分离)
lite 仓 + N 个业务仓物理分离, 通过 env var (`$COLLAB_ROOT` 指向 lite 仓, `$REPO_*` 指向各业务仓) 引用。

**约束**:
- 每个 git 操作的 cwd 必须明确是哪个 repo
- 跨仓 prompt 引用文件路径必须含 env var 前缀

---

## 一 · 新项目 bootstrap (Human 主导, ~1h)

> lite 中无 Claude bootstrap session。Human 用 Lead 当辅助,跑下面 5 步 (+ 可选 Step 0.5)。

### 1. 复制骨架 (5 分钟, 机械)

```bash
STARTER_LITE=<本 lite 仓所在路径>    # 例如 ~/Alcedo/code/ai-collab-starter-lite
DST=<新项目目录>

cp -r "$STARTER_LITE/.ai"        "$DST/.ai"
cp    "$STARTER_LITE/AGENTS.md"  "$DST/AGENTS.md"
cp -r "$STARTER_LITE/scripts"    "$DST/scripts" 2>/dev/null || true
cp -r "$STARTER_LITE/.claude"    "$DST/.claude" 2>/dev/null || true

echo "v0.1.0-lite · synced $(date +%Y-%m-%d)" > "$DST/.ai/STARTER_VERSION"
```

### 2. 清空动态内容 (2 分钟)

```bash
cd "$DST"
echo "# Progress" > .ai/progress.md
# review.md decisions.md state.md plan.md 各自保留模板/表头, 删具体内容
rm -rf .ai/tasks/* .ai/logs/* .ai/archive/* .ai/scratch/* 2>/dev/null || true
```

### 3. 开 4 终端 / 4 会话 (3 分钟 · v0.4 加 Desktop 形态 · F02-self)

lite 的 "4 终端" 是 **session 抽象**, 不绑死 UI 形态。任选一种实际形态:

#### 形态 A · Desktop app (推荐 · 主流)

- **Lead Desktop**: 开 1 个 chat 会话 (= T1 lead engineer)
- **agent app**: 开 3 个**独立** chat 会话 (= T2 Helper / T3 Impl / T4 Reviewer)
  - 关键纪律 (workflow §0): T3 Impl ↔ T4 Reviewer **必须不同会话** (防自审盲点; 两者同属 worker 角色, 同 session 有共谋风险)
- Human 在两个 app 间切 + 复制 prompt (Pattern A)

#### 形态 B · tmux 4 panes (CLI / TUI 用户)

```bash
tmux new -s lite-epic-<name>
# 然后:
#   Ctrl-B "    水平分屏
#   Ctrl-B %    垂直分屏
# 直到 4 panes (每个 pane 跑一个 agent app, 工具品牌自选):
#   T1 (top-left)     : Lead     (主驱动)
#   T2 (top-right)    : Helper   (按需启动)
#   T3 (bottom-left)  : Impl
#   T4 (bottom-right) : Reviewer
```

#### 形态 C · iTerm 4 tabs (CLI / TUI 用户 · macOS)

4 个 tab 分别命名 T1-T4 跑对应 agent。

#### 单终端探索模式(初次试水 / Tiny task · 任意形态都可降级)
- T1 Lead 同时模拟 Impl(临时授权,标 `human-override-lead-fix`)
- T4 Reviewer 仍开独立 session (防自审盲点)
- T2 Helper 不需要

### 4. 在 T1 Lead 跑 bootstrap 喂下方启动话术 (30-45 分钟)

> lite 中无 Claude 大 token bootstrap。Lead 直接读项目元数据 + 写三份草稿。

```text
你是 Lead, lite v0.1.0 lead engineer。本次任务: 新项目 <PROJECT_NAME> bootstrap 协作框架。

按 .ai/getting-started.md §1 Step 4 描述操作:
1. 读 <REPO_PATH> 的 README、package.json/go.mod/Cargo.toml/build.gradle 等顶层元数据
2. 用 ls / find 探查目录结构, 不要读源码细节
3. 输出三份草稿到对应路径:
   - <PROJECT>/.ai/context.md: 项目身份、仓库地图、关键边界、当前状态
   - <PROJECT>/.ai/architecture.md: 架构原则、模块划分、协议边界
   - <PROJECT>/AGENTS.md (在 lite 模板基础上填实): 项目特定的 Tech Stack、Build Commands、
     Known Sharp Edges (初版可空, 后续累积)
4. 输出每份文件的最终内容, Human 审后再 commit
5. 单次会话内完成, 不要切片

不要:
- 扫源码细节 (那是 Helper 的活, 暂不需要)
- 编造未读到的项目细节
- 复述 lite kit 中已经存在的普适约束
```

### 4.5 (可选 · v0.2.0 · F03) · GitNexus 索引接入

**判断条件**: 满足任一即建议接入 GitNexus
- 项目 ≥ 50 KLOC
- 多语言混合 (e.g. Java + TypeScript / C++ + Python)
- 跨 ≥ 5 子项目 (e.g. smart-uite 30 子项目)
- 含复杂 call chain (IPC / RPC / event-driven)

**接入步骤**:
```bash
# 单仓
npx gitnexus analyze .

# 多仓 (umbrella + 子 git): MCP tool group_sync
# 在 Claude / Lead chat 中: mcp__gitnexus__group_sync(<group-name>)
```

**验证 (5 条试探 query, 跑通即接入成功)**:
- 找最常用 export 符号 (`mcp__gitnexus__query` 找 main / start / init)
- 跨子项目 caller (`mcp__gitnexus__impact` 找某公共 header 的影响面)
- 入口 + call chain (`mcp__gitnexus__api_impact` 查跨 repo export)

接入后, 02 brief / L2 摸排走双路并行 (符号级 GitNexus + 文本级 Helper), 详见:
- `.ai/gitnexus-integration.md` (本仓 v0.2.0 新文件)
- `.ai/workflow.md > §8.6 L2 摸排双路并行模式`
- `.ai/prompts/02-lead-plan.md > §6 工具优先级` + `§7 Delegation candidates`

不接的项目沿用 v0.1 单路 Helper, 无影响。

### 5. Human 审 + 修正 (10-15 分钟)

Lead 写的有偏差或漏掉的项目特性, Human 手动改对。常见漏项:

- 私有部署 / 内部工具(README 没写的约定)
- 团队特殊 git 工作流
- 上线 / 发布流程

### 完成的标志

- `AGENTS.md` Tech Stack / Build Commands / Sharp Edges 段填了项目特定内容
- `.ai/context.md` Repo Map / Current State 填实
- `.ai/architecture.md` 至少有架构边界文字描述
- `.ai/decisions.md` 至少 1 个 bootstrap ADR
- 之后任何新需求 / bug 都从此 baseline 出发

---

## 二 · 新需求第一步:按规模路由

> 核心:**流程开销不该 > 任务本身工作量**。先评估规模,再选入口。

### v0.3 新增: 一句话粗描述入口 (Lead 01-intake)

不想先写 brief? 把一句话喂 T1 Lead + 加载 `.ai/prompts/01-lead-intake.md` 契约, Lead 反问 ≤ 5 个澄清问题, 你答完它产 brief 文件 (落 `.ai/tasks/<id>.md`)。

```text
你是 Lead。按 .ai/prompts/01-lead-intake.md 契约执行。
一句话需求: <你的一句话>
反问 ≤ 5 个澄清问题, 我答完你写 brief 文件。
```

适用场景: 需求细节还没想清 / 类型 (feature vs bug vs refactor) 模糊 / 想偷懒。
详见 `.ai/prompts/01-lead-intake.md > §触发边界` + `.ai/workflow.md > §1 双入口`。

### 路由表 (lite 版 · v0.3 加 01-intake 行)

| 规模 | 标志 | 入口 | 跑哪些 prompt | 何时止步 |
| --- | --- | --- | --- | --- |
| **Tiny** | < 30 行、单文件、命名调整、文档改字 | 单 Agent 单轮对话 | 不走框架 | commit 即止 |
| **Small** | 1-2 小时、单模块、行为清晰 | Human 直接写 task 文件 **或** Lead 01-intake (v0.3) | (01-intake 可选)→ 02(Lead)→ 03a/b/c → 04 Reviewer → 合入 | review 通过即合入 |
| **Medium** | 半天-1 天、多文件、需权衡 | Human 写一两段 brief **或** Lead 01-intake (v0.3) | (01-intake 可选)→ 02 → 03a/b/c → 04 → 合入(4 终端) | 同上 |
| **Large** | 多日、跨模块、可能跨仓 | Human 写 brief 标 Large **或** Lead 01-intake (v0.3) | (01-intake 可选)→ 02(切片 ≤3)→ 多次 03 三段式 → 04 各 slice → epic-level review | 切片全部合入 |
| **Epic** | 多周、跨多目标 | `.ai/plan.md` 建 epic 章节 **或** Lead 01-intake (v0.3 · 产 epic plan) | (01-intake 可选)→ epic 拆 ≥3 个 task 文件, 各自走 Large | 整 epic 收口 |

### Brief 最小模板 (Medium / Large 起用)

```markdown
---
task-id: <epic-id-slice-N 或 task-id>
size: Tiny | Small | Medium | Large | Epic
human-escalation-suggested: false | true
created: YYYY-MM-DD
---

# Brief: <一句话需求>

## What
<2-3 句具体要做什么 / 现状什么样>

## Why
<为什么现在做、不做的代价>

## Boundaries
- In scope: <列表>
- Out of scope: <列表>

## Acceptance hint
<一句话定义"完成的样子", 不必精确, 由后续阶段细化>

## Known constraints
<已知的技术限制 / 截止时间 / 依赖>
```

把这段贴给 T1 Lead 启动 02。

### Small 任务的 task 文件最小模板

```markdown
---
task-id: <id>
size: Small
human-escalation-suggested: false
created: YYYY-MM-DD
---

# Task: <name>

## Goal
<一段话>

## Scope
- Repo: <path>
- Paths (核心): <list>
- Paths (连带, 允许小改): <list>

## Pre-decisions (≥ 3 条)
- D1: ...
- D2: ...
- D3: ...

## Non-goals
- <list>

## Acceptance Criteria
1. ...
2. ...

## Tests
<commands>

## Review checklist
- [ ] ...
```

直接喂给 T1 Lead 02-lead-plan.md(或若 Small 简单,Lead 02 一次产 brief + 子任务包合并)。

### 「跳过哪一步」纪律 (lite)

| 跳过 | 何时合理 | 何时危险 |
| --- | --- | --- |
| 跳 Lead 02 直接 03a | task 已是 brief 形式 + Small | Medium+ 禁止跳, 容易扩 scope |
| 跳 Lead 03a 子任务包(让 Impl 自己理解 brief) | **禁止**, 这是 lite 设计核心 | 总是危险 |
| 跳 Reviewer 04 | task 标 `skip-review: true` 且 < 30 行单文件 | 默认不跳——便宜的最后扫雷 |
| 跳 4 终端只用 1 终端 | Tiny / Small 初次试水 | Medium+ 禁止——session 隔离破坏 |

---

## 三 · Bug 处理:加一道「先复现」纪律

> **不需要新增 prompt**。lite 5 prompt 完全能处理 bug, 流程差三道纪律。

### Bug 流程速记 (lite)

```
Step 1: Helper 跑 bug 复现路径 grep / 嫌疑 commit 区间 scan (写 out-*.md)
Step 2: L2 摸排 (v0.2.0 · F04 双路并行)
        - 2a: Helper 跑文本级 grep (req-<bug>-N.md, F11 默认过滤第三方)
        - 2b: Lead 自跑 GitNexus 符号级查询 (gitnexus-<bug>-N.md), 若项目已接 GitNexus
        - Lead 02 finalize brief 时双源汇总
Step 3: Lead 02 修复策略决策 (minimal patch / refactor-with-fix / defer + workaround)
Step 4: Lead 03a 拆任务 → Impl 03b 实施 → Lead 03c 验收 (必须含回归测试)
Step 5: Reviewer 04 (专门检查回归测试有效性 + bug 任务两阶段证据 · F10)
Step 6: Human 合入 + 关闭 review.md 中对应 finding
```

### 差异 1 · Bug Brief 模板

bug 的 Step 1 输入比 feature 多两段:

```markdown
---
task-id: bug-<date>-<slug>
size: ...
severity: P0 | P1 | P2 | P3
human-escalation-suggested: <若 P0/P1 通常 true>
created: YYYY-MM-DD
---

# Bug Brief: <现象一句话>

## Reproduction
<若已确认: 具体步骤、命令、输入、环境, 别人能按这个 repro 出来>
<若未确认 (v0.2.0 · F07): 标"复现路径未确认", 列 ≥ 2 条嫌疑触发路径, 标"待 L2 摸排 + 复现验证">

## 复现要求 (修复必带 · v0.2.0 · F07)
<未确认场景下显式要求: 03a 拆任务前必须有 ≥ 1 条 confirmed repro 路径>
<复现脚本路径 (e.g. tests/<bug-id>_repro.ps1) + pre-patch fail 关键断言>
<post-patch pass 验证流水>

## Expected vs Actual
- Expected: <应有行为>
- Actual: <实际行为, 附 log / 截图 / 错误码 / stack trace>

## When did it start?
<最近一次 work 的时间 / commit; 最近一次 break 在哪>

## Initial hypothesis
<可选>

## Severity
P0 / P1 / P2 / P3
```

### Severity → human-escalation-suggested 默认映射 (v0.2.0 · F06)

| Severity | 默认 `human-escalation-suggested` | 例外情况 |
| --- | --- | --- |
| P0 (线上事故 / 阻塞用户 / 数据损坏) | `true` | 紧急通道明确跳 02 → minimal hotfix 时 `false` |
| P1 (功能错乱 / 体验严重影响 / 资源冲突) | `true` | 修复路径明确单选, Human 不需介入决策时 `false` |
| P2 (功能瑕疵 / 边界 case 错误) | `false` | 涉及架构敏感字段 (注解 / SPI / 配置结构) 改 `true` |
| P3 (typo / 文档 / 不影响行为) | `false` | 改 lite 框架本身 prompt 时 `true` (走 lite-upgrade-protocol) |

不严格强制, 但偏离默认时**必须在 brief 末尾 "Why this severity-escalation combination" 段说明理由**。

Helper 跑的 packet 多两段:

- **稳定复现路径**(明确步骤, Human 能照做)
- **嫌疑 commit 区间**(git log + 可能的 bisect 候选)

### 差异 2 · Lead 02 修复策略三选一

bug 的 02 brief Decision 段必须明确:

| 策略 | 何时用 | 风险 |
| --- | --- | --- |
| **Minimal patch** | 多数 bug; 改几行能解决 | 可能掩盖深层设计问题 |
| **Refactor-with-fix** | bug 暴露架构问题, 顺带改 | scope 容易爆; 务必明确收益 |
| **Defer + workaround** | root cause 太大; 先临时 workaround | workaround 本身可能成新债; 必须开 follow-up issue |

紧急生产 bug 一律走 minimal patch + workaround, 不允许 refactor。

### 差异 3 · 实施必须带回归测试

bug task 文件 Acceptance Criteria 必须包含:

```markdown
## Acceptance Criteria
- [ ] 回归测试: 复现脚本 / 单测能在 patch 前 fail, patch 后 pass
- [ ] 测试名 / 测试 docstring 包含 issue 或 bug 编号, 方便日后 grep
- [ ] 该回归测试加入常规测试套件 (CI 默认跑)
- [ ] (v0.2.0 · F07) 若 Reproduction 标"未确认", 03b 必须先 L2 复现验证 (至少 1 条嫌疑路径变成 confirmed), 才能进 03c 验收
- [ ] (v0.2.0 · F10) chat / progress.md 含 bug 测试两阶段证据 (pre-patch FAIL + post-patch PASS) — 03b 必须显式输出, 03c 必须验证, 04 必须 cross-check
```

Lead 03c 验收对 bug 任务**额外**检查:

- 测试代码**真的**跑了 bug 的代码路径, 不是空跑
- 临时 revert patch 后测试**确实 fail** (静态确认逻辑覆盖)

### 差异 4 · Review 纪律

bug 必须作为 finding 在 `.ai/review.md` 追踪 (格式同 main, 略)。

合入后 status 由 verifier(不是修复人)翻 `verified`, 否则不算关闭。

### 紧急 bug 快速通道

生产事故 / 阻塞用户的 P0 bug 允许:

- 跳过 Step 1 Helper packet——**Human** 直接写复现到 task 文件
- 跳过 Step 2 完整 02——**先**打 minimal hotfix 合入(Human override Lead 临时写),**事后** 24h 内补 ADR
- 跳过 Step 4 Reviewer——Lead 03c 自审 + Human review 即可

但**绝不**允许:

- 跳过回归测试
- 不开 review.md finding
- 事后不补 ADR

紧急通道用过一次必须在 progress.md 记一笔, 月底统计本月用了几次。

---

## 四 · Epic 收口 (v0.4 新增 · F01-self)

epic merge 完后必须跑收口, 否则下个 epic 启动时 context 污染 (state.md 残留 / scratch 残留)。

两种入口:

### 入口 A: Human 手动跑 checklist
按 `.ai/workflow.md > §9 Epic closeout (收口)` 清单逐项执行 (清 ephemeral + 留持久 + 机器化 verify)。

### 入口 B (推荐): Lead 09-closeout 协助
喂 T1 Lead:
```text
你是 Lead。按 .ai/prompts/09-lead-closeout.md 契约执行 epic 收口.
epic: <epic-id> 完了, merge commit <hash>, outcome: <一句话>.
```

Lead 跑 4 步流 (验证前置条件 → 清 → 留 → 收口验证 5 项 PASS) 自动完成。

---

## 五 · 什么情况都别套这个框架

明确**不**该走的场景:

- < 30 行的 typo / 注释 / 命名调整 / README 改字
- 写一封邮件、博客、聊天回复草稿
- 探索性原型 / Jupyter notebook 灵感期 / spike
- 一次性临时脚本, 不需要审计追溯
- 写完即弃的 demo 代码

这些场景直接和**一个** Agent 单轮对话最快。框架是加速器, 不是仪式。

---

## 六 · 把这份文档当 reference

每次开始工作前先读本文 §1-§3 对应段, 问自己:

1. 这是新项目还是已有项目?
2. 是新需求还是 bug?
3. 规模属于 Tiny / Small / Medium / Large / Epic 哪一档?
4. 要开几个终端? (Tiny: 1, Small: 1-2, Medium+: 4)

确定后直接走对应入口, 不要每次都重新设计流程。

发现新踩的坑 → 追加到 `AGENTS.md > Known Sharp Edges`。
发现入口流程缺陷 → 改本文。
发现某 prompt 不够用 → 改 `.ai/prompts/0X-*.md`。

文档活的才有用。
