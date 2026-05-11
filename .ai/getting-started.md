# Getting Started

> 入口文档。三类常见情境都能在这里找到答案：
>
> - 新项目第一步
> - 新需求第一步（按规模路由）
> - Bug 处理流程
>
> 与其他 .ai/ 文件区别：
> - `README.md` 解释目录结构
> - `workflow.md` 解释 7 步法
> - `getting-started.md`（本文）解释**怎么开始**——目的不同

---

## 一、新项目第一步：手动 bootstrap

> 自动化引导脚本见 `scripts/init-collab.sh`。手动启动也只需 5 步、约 1 小时。

### 5 步（约 1 小时）

#### 1. 复制骨架（5 分钟，机械）

```bash
STARTER=<本 starter kit 所在路径>     # 例如 ~/ai-collab-starter
DST=<新项目目录>

cp -r "$STARTER/.ai"        "$DST/.ai"
cp    "$STARTER/AGENTS.md"  "$DST/AGENTS.md"
cp -r "$STARTER/scripts"    "$DST/scripts"
cp -r "$STARTER/.claude"    "$DST/.claude"
```

或一条命令跑自动化脚本：

```bash
$STARTER/scripts/init-collab.sh --target "$DST" --name "<PROJECT_NAME>"
```

#### 2. 清空动态内容（2 分钟）

```bash
cd "$DST"
echo "# Progress" > .ai/progress.md
# review.md decisions.md state.md plan.md 各自保留模板/表头，删具体内容
rm -rf .ai/tasks/* .ai/logs/* .ai/archive/* 2>/dev/null || true
```

#### 3. 写第一个 ADR（5 分钟，人手写）

在 `.ai/decisions.md` 追加：

```markdown
## ADR-YYYYMMDD-01: 采用多 Agent 协同框架

- Status: accepted
- Owner: <human>
- Date: YYYY-MM-DD
- Repos affected: <list>
- Context: 新项目 <PROJECT_NAME> 启动，引入多 Agent 协同框架（Claude Code + Codex + OpenCode）以应对中-大型工作量的可追溯性需求。
- Decision:
  - Claude Code 负责架构决策与高风险评审
  - Codex 负责实施、审校、修复
  - OpenCode 负责上下文摸排、草稿实施、低成本 review、文档维护
  - 工作目录与日志统一在 .ai/，源码在真实仓
- Alternatives considered: 单 Agent 全包；不引入框架。
- Consequences:
  - 任务 ≥ 2 小时工作量者必走 task 文件 + 三阶段流水
  - 成本：约一次 Claude bootstrap session（30-45 分钟）+ 持续轻量维护
- Follow-up: 跑通第一个真实任务后复盘是否需要调整角色边界。
```

#### 4. Claude bootstrap session（30-45 分钟，最贵一步）

把以下 prompt 喂给 Claude——**唯一**应该让 Claude 在新项目花大 token 的地方：

```text
你是 Claude Code。本次任务为新项目 <NAME> bootstrap 协作框架。

操作：
1. 读 <REPO_PATH> 的 README、package.json/go.mod/Cargo.toml/build.gradle 等顶层元数据
2. 用 ls / find 探查目录结构，不要读源码细节
3. 输出三份草稿到对应路径：
   - <PROJECT>/.ai/context.md：项目身份、仓库地图、关键边界、当前状态
   - <PROJECT>/.ai/architecture.md：架构原则、模块划分、协议边界
   - <PROJECT>/AGENTS.md（在 starter 模板基础上填实）：项目特定的 Tech Stack、Build Commands、
     Known Sharp Edges（初版可空，后续累积）
4. 输出每份文件的最终内容，人审后再提交
5. Token 限制：单次会话内完成，不要切片

不要：
- 扫源码细节
- 编造未读到的项目细节
- 复述 starter kit 中已经存在的普适约束（那些读者已经读过）
```

#### 5. 人审 + 修正（10-15 分钟）

Claude 写的有偏差或漏掉的项目特性，手动改对。常见漏项：

- 私有部署 / 内部工具（README 没写的约定）
- 团队特殊 git 工作流
- 上线 / 发布流程

### 完成的标志

- `AGENTS.md` Tech Stack / Build Commands / Sharp Edges 段填了项目特定内容
- `.ai/context.md` Repo Map / Current State 填实
- `.ai/architecture.md` 至少有架构边界文字描述
- `.ai/decisions.md` 至少 1 个 bootstrap ADR
- 之后任何新需求 / bug 都从此 baseline 出发

---

## 二、新需求第一步：按规模路由

> 核心：**流程开销不该 > 任务本身工作量**。先评估规模，再选入口。

### 路由表

| 规模 | 标志 | 入口 | 跑哪些 prompt | 何时止步 |
| --- | --- | --- | --- | --- |
| **Tiny** | < 30 行、单文件、命名调整、文档改字 | 单 Agent 单轮对话 | 不走框架 | commit 即止 |
| **Small** | 1-2 小时、单模块、行为清晰 | 人直接写 task 文件 | 03（Codex 实施）→ 04（OC review）→ 合入 | review 通过即合入 |
| **Medium** | 半天-1 天、多文件、需权衡 | 人写一两段 brief | 01 → 02 → 03 → 04 → 合入 | 同上 |
| **Large** | 多日、跨模块、可能跨仓 | 人写 brief 标 Large | 01 → 02（切片 ≤3）→ 多次 (07+08) → 04 合入前 | 切片全部合入 |
| **Epic** | 多周、跨多目标（如 P0 系列） | `.ai/plan.md` 建 epic 章节 | epic 拆 ≥3 个 task 文件，各自走 Large | 整 epic 收口 |

### Brief 最小模板（Medium / Large 起用）

```markdown
# Brief: <一句话需求>

## What
<2-3 句具体要做什么 / 现状什么样>

## Why
<为什么现在做、不做的代价>

## Boundaries
- In scope: <列表>
- Out of scope: <列表>

## Acceptance hint
<一句话定义"完成的样子"，不必精确，由后续阶段细化>

## Known constraints
<已知的技术限制 / 截止时间 / 依赖>
```

把这段贴给 OC（用 `01-opencode-context.md` 模板）即可启动。

### Small 任务的 task 文件最小模板

```markdown
# Task: <name>

## Goal
<一段话>

## Scope
- Repo: <path>
- Paths: <list>

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

直接喂给 Codex（`03-codex-implement.md`）。

### 「跳过哪一步」纪律

| 跳过 | 何时合理 | 何时危险 |
| --- | --- | --- |
| 跳 OC 摸排（01） | task 写得已够清楚 / Small | Medium 以上禁止跳——容易扩 scope |
| 跳 Claude 决策（02） | scope 满足 `AGENTS.md > Scope Heuristics` 的 Claude 直改条件 | 跨仓 / 协议改动禁止跳 |
| 跳 OC review（04） | Codex 自审 + Claude 评审已覆盖 | 不要跳——便宜的最后一道扫雷 |
| 跳 Claude 评审（05） | OC 没标 escalate | OC 标了就不能跳 |

---

## 三、Bug 处理：现有流程兼容，加一道「先复现」纪律

> **不需要新增 prompt**。现有 8 个完全能处理 bug，只是流程差三道纪律。

### Bug 流程速记

```
Step 1: OC bug packet（含复现路径 + 嫌疑 commit 区间）
Step 2: Claude 修复策略决策（minimal patch / refactor-with-fix / defer + workaround）
Step 3: Codex / OC 实施 + 回归测试（必须）
Step 4: OC review（专门检查回归测试有效性）
Step 5: 合入 + 关闭 review.md 中对应 finding
```

### 差异 1 · Bug Brief 模板

bug 的 Step 1 输入比 feature 多两段：

```markdown
# Bug Brief: <现象一句话>

## Reproduction
<具体步骤、命令、输入、环境>
<必须能让别人按这个 repro 出来>

## Expected vs Actual
- Expected: <应有行为>
- Actual: <实际行为，附 log / 截图 / 错误码 / stack trace>

## When did it start?
<最近一次 work 的时间 / commit；最近一次 break 在哪>
<git bisect 候选区间，如已知>

## Initial hypothesis
<可选；OC 调研后会确认或推翻>

## Severity
P0 / P1 / P2 / P3（参考 review.md > Severity 定义）
```

OC 的 packet 输出多两段：

- **稳定复现路径**（明确步骤，人能照做）
- **嫌疑 commit 区间**（git log + 可能的 bisect 候选）

### 差异 2 · Claude 修复策略三选一

bug 的 02 ADR `Decision` 段必须明确：

| 策略 | 何时用 | 风险 |
| --- | --- | --- |
| **Minimal patch** | 多数 bug；改几行能解决 | 可能掩盖深层设计问题 |
| **Refactor-with-fix** | bug 暴露架构问题，顺带改 | scope 容易爆；务必明确收益 |
| **Defer + workaround** | root cause 太大；先临时 workaround，root cause 另立项 | workaround 本身可能成新债；必须开 follow-up issue |

紧急生产 bug 一律走 minimal patch + workaround，不允许 refactor。

### 差异 3 · 实施必须带回归测试

bug task 文件 Acceptance Criteria 必须包含：

```markdown
## Acceptance Criteria
- [ ] 回归测试：复现脚本 / 单测能在 patch 前 fail、patch 后 pass
- [ ] 测试名 / 测试 docstring 包含 issue 或 bug 编号，方便日后 grep
- [ ] 该回归测试加入常规测试套件（CI 默认跑）
```

08 Codex 审校对 bug 任务**额外**检查（在通用第 4 步之上）：

- 测试代码**真的**跑了 bug 的代码路径，不是空跑
- 临时 revert patch 后测试**确实 fail**（如条件允许；不能 revert 时至少要静态确认逻辑覆盖）

### 差异 4 · Review 纪律

bug 必须作为 finding 在 `.ai/review.md` 追踪：

```markdown
### RV-YYYYMMDD-NN: <bug 标题>

- Severity: P0 | P1 | P2 | P3
- Reporter: <人 / Agent / 监控告警>
- Owner: Codex（或 OC 草稿）
- Verifier: <Reporter 或指定人>
- Repo: <path>
- File/symbol: <精确定位>
- Status: open | accepted | in-progress | fixed | verified | rejected | deferred
- Finding: <现象 + root cause>
- Expected fix: <策略 minimal/refactor/defer 之一>
- Verification: <回归测试名 + 真机或环境验证步骤>
```

合入后 status 由 verifier（不是修复人）翻 `verified`，否则不算关闭。

### 紧急 bug 快速通道

生产事故 / 阻塞用户的 P0 bug 允许：

- 跳过 Step 1 OC packet——**人**直接写复现到 task 文件
- 跳过 Step 2 ADR——**先**打 minimal hotfix 合入，**事后** 24 小时内补 ADR
- 跳过 Step 4 OC review——Codex 自审 + 人 review 即可

但**绝不**允许：

- 跳过回归测试
- 不开 review.md finding
- 事后不补 ADR（如果跳过了 Step 2）

紧急通道用过一次必须在 progress.md 记一笔，月底统计：本月用了几次紧急通道，是否有可流程化避免的根因。

---

## 四、什么情况都别套这个框架

明确**不**该走的场景：

- < 30 行的 typo / 注释 / 命名调整 / README 改字
- 写一封邮件、博客、聊天回复草稿
- 探索性原型 / Jupyter notebook 灵感期 / spike
- 一次性临时脚本，不需要审计追溯
- 写完即弃的 demo 代码

这些场景直接和**一个** Agent 单轮对话最快。框架是加速器，不是仪式。

---

## 五、把这份文档当 reference

每次开始工作前先读本文 §1-§3 对应段，问自己：

1. 这是新项目还是已有项目？
2. 是新需求还是 bug？
3. 规模属于 Tiny / Small / Medium / Large / Epic 哪一档？

确定后直接走对应入口，不要每次都重新设计流程。

发现新踩的坑 → 追加到 `AGENTS.md > Known Sharp Edges`。
发现入口流程缺陷 → 改本文。
发现某 prompt 不够用 → 改 `.ai/prompts/0X-*.md`。

文档活的才有用。
