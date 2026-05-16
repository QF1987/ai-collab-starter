# Getting Started (lite v0.1.0)

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

## 一 · 新项目 bootstrap (Human 主导, ~1h)

> lite 中无 Claude bootstrap session。Human 用 Codex 当辅助,跑下面 5 步。

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

### 3. 开 4 终端 (3 分钟)

```bash
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

**单终端探索模式**(初次试水 / Tiny task):
- T1 Codex 同时模拟 OC-impl(临时授权,标 `human-override-codex-fix`)
- T4 OC-review 仍开独立终端(防自审盲点)
- T2 OC-helper 不需要

### 4. 在 T1 Codex 跑 bootstrap 喂下方启动话术 (30-45 分钟)

> lite 中无 Claude 大 token bootstrap。Codex 直接读项目元数据 + 写三份草稿。

```text
你是 Codex, lite v0.1.0 lead engineer。本次任务: 新项目 <PROJECT_NAME> bootstrap 协作框架。

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
- 扫源码细节 (那是 OC-helper 的活, 暂不需要)
- 编造未读到的项目细节
- 复述 lite kit 中已经存在的普适约束
```

### 5. Human 审 + 修正 (10-15 分钟)

Codex 写的有偏差或漏掉的项目特性, Human 手动改对。常见漏项:

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

### 路由表 (lite 版)

| 规模 | 标志 | 入口 | 跑哪些 prompt | 何时止步 |
| --- | --- | --- | --- | --- |
| **Tiny** | < 30 行、单文件、命名调整、文档改字 | 单 Agent 单轮对话 | 不走框架 | commit 即止 |
| **Small** | 1-2 小时、单模块、行为清晰 | Human 直接写 task 文件 | 02(Codex)→ 03a/b/c → 04 OC-review → 合入 | review 通过即合入 |
| **Medium** | 半天-1 天、多文件、需权衡 | Human 写一两段 brief | 02 → 03a/b/c → 04 → 合入(4 终端) | 同上 |
| **Large** | 多日、跨模块、可能跨仓 | Human 写 brief 标 Large | 02(切片 ≤3)→ 多次 03 三段式 → 04 各 slice → epic-level review | 切片全部合入 |
| **Epic** | 多周、跨多目标 | `.ai/plan.md` 建 epic 章节 | epic 拆 ≥3 个 task 文件, 各自走 Large | 整 epic 收口 |

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

把这段贴给 T1 Codex 启动 02。

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

直接喂给 T1 Codex 02-codex-plan.md(或若 Small 简单,Codex 02 一次产 brief + 子任务包合并)。

### 「跳过哪一步」纪律 (lite)

| 跳过 | 何时合理 | 何时危险 |
| --- | --- | --- |
| 跳 Codex 02 直接 03a | task 已是 brief 形式 + Small | Medium+ 禁止跳, 容易扩 scope |
| 跳 Codex 03a 子任务包(让 OC-impl 自己理解 brief) | **禁止**, 这是 lite 设计核心 | 总是危险 |
| 跳 OC-review 04 | task 标 `skip-review: true` 且 < 30 行单文件 | 默认不跳——便宜的最后扫雷 |
| 跳 4 终端只用 1 终端 | Tiny / Small 初次试水 | Medium+ 禁止——session 隔离破坏 |

---

## 三 · Bug 处理:加一道「先复现」纪律

> **不需要新增 prompt**。lite 5 prompt 完全能处理 bug, 流程差三道纪律。

### Bug 流程速记 (lite)

```
Step 1: OC-helper 跑 bug 复现路径 grep / 嫌疑 commit 区间 scan (写 out-*.md)
Step 2: Codex 02 修复策略决策 (minimal patch / refactor-with-fix / defer + workaround)
Step 3: Codex 03a 拆任务 → OC-impl 03b 实施 → Codex 03c 验收 (必须含回归测试)
Step 4: OC-review 04 (专门检查回归测试有效性)
Step 5: Human 合入 + 关闭 review.md 中对应 finding
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
<具体步骤、命令、输入、环境>
<必须能让别人按这个 repro 出来>

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

OC-helper 跑的 packet 多两段:

- **稳定复现路径**(明确步骤, Human 能照做)
- **嫌疑 commit 区间**(git log + 可能的 bisect 候选)

### 差异 2 · Codex 02 修复策略三选一

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
```

Codex 03c 验收对 bug 任务**额外**检查:

- 测试代码**真的**跑了 bug 的代码路径, 不是空跑
- 临时 revert patch 后测试**确实 fail** (静态确认逻辑覆盖)

### 差异 4 · Review 纪律

bug 必须作为 finding 在 `.ai/review.md` 追踪 (格式同 main, 略)。

合入后 status 由 verifier(不是修复人)翻 `verified`, 否则不算关闭。

### 紧急 bug 快速通道

生产事故 / 阻塞用户的 P0 bug 允许:

- 跳过 Step 1 OC-helper packet——**Human** 直接写复现到 task 文件
- 跳过 Step 2 完整 02——**先**打 minimal hotfix 合入(Human override Codex 临时写),**事后** 24h 内补 ADR
- 跳过 Step 4 OC-review——Codex 03c 自审 + Human review 即可

但**绝不**允许:

- 跳过回归测试
- 不开 review.md finding
- 事后不补 ADR

紧急通道用过一次必须在 progress.md 记一笔, 月底统计本月用了几次。

---

## 四 · 什么情况都别套这个框架

明确**不**该走的场景:

- < 30 行的 typo / 注释 / 命名调整 / README 改字
- 写一封邮件、博客、聊天回复草稿
- 探索性原型 / Jupyter notebook 灵感期 / spike
- 一次性临时脚本, 不需要审计追溯
- 写完即弃的 demo 代码

这些场景直接和**一个** Agent 单轮对话最快。框架是加速器, 不是仪式。

---

## 五 · 把这份文档当 reference

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
