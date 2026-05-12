# Intake Templates

> 任务/Bug/Bootstrap 启动前的结构化提问模板。问题库 + 产出格式的**单一来源**。
>
> 两个访问入口共用本文件：
> - `.claude/skills/intake/SKILL.md`（Claude Code 自动 skill，UX 最优）
> - 任何 Agent 手动调用（OpenCode / Codex 把本文件当 prompt 直接读）
>
> 用法：模型按下面分支问问题、收答案、产出草稿、**让人审过**才落盘。

---

## 模式选择（必须问的第 0 题 · 用户体验入口）

```
Q-1. 你的需求处于什么阶段？

  A. 探索式（推荐起步）—— 我说 2-3 句大体想法，agent 替我拼 brief 草稿，
                          我审改红字。适合「脑子里只有粗略方向」。
  B. 问答式（精确版）  —— 我心里清楚，agent 7 题一一问，我精确答。
                          适合「需求已经想透」。
```

**两种模式的产出**：完全相同（同一份 brief / task / ADR），只是收集人答案的方式不同。

> **探索式有一个变体 · Agent 全权设计**：当用户**明确授权** agent 拍板（典型话术：「你自己设计就行」/「按经验拍板」/「细节我不管」），走 `§A · 探索式工作流` 但**第 2 步 agent 试填**的字段 80-95% 标 `[推断]`，仅保留 1-2 处真正不能瞎拍的（典型：技术栈选型、scope 边界、有无写操作）为 `[待确认]`。用户审核成本降低，但 `[推断]` 透明化纪律不变。详见 `.claude/skills/intake/SKILL.md > 探索式 · Agent 全权设计变体`。

### A · 探索式 intake 工作流（推荐）

1. **第 1 步 · 散文输入**：agent 让人输入 1-3 句话描述「想做什么 + 为什么」。
2. **第 2 步 · agent 试填**：agent 解析散文 + 推断 + 试填全部字段：
   - 用人原话能直接抽到的内容 → 标记 `[原话]` 前缀
   - agent 推断补充的内容 → 标记 `[推断]` 前缀 + 一句话说推断理由
   - 不确定 / 没信息支撑的字段 → 标记 `[待确认]` 前缀
3. **第 3 步 · 整体口述**：agent 把试填的 brief 整段口述给人，明显标识三类来源。
4. **第 4 步 · 人审核**：人逐字段反馈（"对" / "改成 X" / "我不知道留 TBD"）。
5. **第 5 步 · 迭代或落盘**：
   - 人说 "继续改" → 回到 第 2 步用新输入重试（**最多迭代 3 轮**）
   - 人说 "go" → 落盘
   - 超过 3 轮还没收敛 → **自动转问答式**（说明需求本身没想清，需要精确化）

### 探索式标识纪律（硬约束）

agent 在每个 brief 字段开头**必须**显式标三类前缀之一：

```markdown
## What
[原话] 标准化 release 状态机与错误码
[推断] 当前 status 字段是字符串拼凑、跨语言无统一来源（推断理由：用户说"标准化"暗含
       当前不标准；具体非标程度待 OC 摸排确认）
[待确认] 是否同时定义 ErrorCode？brief 只提了状态机，未明确包含错误码
```

不允许：

- 字段开头**没有**前缀标记
- 把推断内容标成 `[原话]`（虚假权威）
- 把不确定标成 `[推断]`（佯装有理）

人审时看到 `[推断]` 和 `[待确认]` 段就知道哪里要重点核对。

### B · 问答式 intake 工作流（精确版）

按 §A/B/C 下面的题目流问答，无 agent 推断成分——人答什么 agent 填什么。

---

## 入口分流（探索式 / 问答式 都要问）

```
Q0. 这次工作是什么类型？
  A. 新需求 / 新功能         → 走 §A Task Intake
  B. Bug / 现有功能异常       → 走 §B Bug Intake
  C. 新项目 bootstrap         → 走 §C Bootstrap Intake
  D. 只想 triage 已有想法的规模 → 走 §D Triage-only
```

---

## §A · Task Intake（新需求 / 新功能）

### 问题流

按顺序问。前 3 题必填，其余按规模自适应。

```
Q1. 任务一句话目标？
    （≤ 1 句；将作为 task 文件 H1 标题）

Q2. 你估计的规模？
    A. Tiny     — < 30 行 / 单文件 / 命名调整 / 文档改字
    B. Small    — 1-2 小时 / 单模块 / 行为清晰
    C. Medium   — 半天-1 天 / 多文件 / 需权衡
    D. Large    — 多日 / 跨模块 / 可能跨仓
    E. Epic     — 多周 / 跨多目标
    F. 不确定   — 让我帮你判断（会再问 2 题引导）

Q3. 涉及哪个 repo / 哪些模块？
    （绝对路径或熟悉的代号；Tiny 可只写文件名）
```

**Tiny / Small 到此为止。Medium 起继续：**

```
Q4. 范围内 vs 范围外？
    in-scope: 1-3 项（明确要做的）
    out-of-scope: 1-3 项（明确不做的；这条很重要，写不出来说明 scope 还不清）

Q5. "完成的样子" 一句话描述？
    （后续作为 Acceptance hint；不必精确）
```

**Large / Epic 继续：**

```
Q6. 已知约束 / 截止时间 / 外部依赖？
    （没有就写"无"；不要留空）

Q7. 初始想法 / 偏好 / 之前的尝试？（可选）
```

### Q2.F「不确定规模」的引导

依次问：

```
F1. 涉及几个文件？(1 / 2-5 / 6+)
F2. 涉及几个 repo？(1 / 2 / 3+)
F3. 是否动到对外接口（API/proto/SDK 签名）？(是/否)
F4. 是否动到数据 schema？(是/否)
```

判定矩阵：

| F1 | F2 | F3 | F4 | 推断规模 |
| --- | --- | --- | --- | --- |
| 1 | 1 | 否 | 否 | Small |
| 2-5 | 1 | 否 | 否 | Medium |
| 6+ | 1 | 否 | 否 | Large |
| any | 2+ | any | any | Large 起步 |
| any | any | 是 | any | Medium 起步（协议改动） |
| any | any | any | 是 | Medium 起步（schema 改动） |

把判定结果告诉用户并允许覆盖。

### 产出（按规模分流）

#### Tiny

不产出文件。直接告知：

```
建议：直接和**一个** Agent 单轮对话完成。不走框架。
理由：流程开销 > 任务工作量。
完成后人工 commit 即可，不需要 progress / review 记录。
```

#### Small

产出 `.ai/tasks/<YYYY-MM-DD>-<slug>.md`（最小模板）：

```markdown
# Task: <Q1 答案>

## Goal
<由 Q1 + Q3 合成；1-2 句>

## Scope
- Repo: <Q3 答案>
- Paths: <如有具体文件，否则 TBD by implementer>

## Non-goals
- <Q4 out-of-scope；如未问可写"明确为 Small 任务，不扩范围"></

## Acceptance Criteria
1. <最小验收点；人审时补充>
2. ...

## Tests
<commands ；TBD>

## Review checklist
- [ ] 改动在 Scope 内
- [ ] 未引入新依赖
- [ ] 测试通过

## Handoff state
直接喂 03-codex-implement.md 给 Codex，或人工实施。
```

下一步建议：直接喂 Codex `03-codex-implement.md`。

#### Medium / Large

产出 brief 草稿（**不**直接生成 task 文件——切片由 Claude 决定）：

```markdown
# Brief: <Q1 答案>

## What
<现状 + 目标，由 Q1 + Q3 + Q5 合成；2-3 句>

## Why
<为什么现在做；如未问就标 TODO>

## Boundaries
- In scope: <Q4 in-scope>
- Out of scope: <Q4 out-of-scope>

## Acceptance hint
<Q5 答案>

## Known constraints
<Q6 答案>

## Initial thoughts
<Q7 答案，如有>

## Estimated size
<Medium / Large>
```

写入 `.ai/logs/<YYYY-MM-DD>-<slug>.brief.md`。

下一步建议：

- Medium：喂 OpenCode `01-opencode-context.md` + 这份 brief
- Large：同 Medium，注明「需 Claude 切片 ≤ 3 个 slice」

#### Epic

产出 `.ai/plan.md` 的 epic 章节草稿（追加，不覆盖）：

```markdown
## Epic: <Q1 答案>

- 目标: <一句话>
- 估时: 多周
- 子任务（待 Claude 切片）:
  - TBD
- 已知约束: <Q6>
- 初始想法: <Q7>
```

下一步建议：人审 epic 章节 → 喂 OpenCode 启动第一片调研。

---

## §B · Bug Intake

### 问题流

```
Q1. 现象一句话？
Q2. 严重度？(P0/P1/P2/P3，定义见 .ai/review.md > Severity)
Q3. 复现步骤？
    （具体到命令/输入/环境；写不出来说明 bug 还没到能修的阶段，先停下复现）
Q4. Expected vs Actual？
    Expected: <应有行为>
    Actual:   <实际行为；附 log / stack / 错误码片段>
Q5. 何时开始坏？最近一次 work 是什么时候？
    （回答可以是 commit hash / 日期 / 版本号 / "不知道"）
```

**P0/P1 增问：**

```
Q6. 是否走紧急通道？
    紧急通道允许：跳 Step 1 OC packet（人直接写 task）+ 跳 Step 2 ADR（先 hotfix 后补）
    紧急通道不允许跳：回归测试、review.md finding、事后 ADR
    （是 / 否 / 不确定让我建议）
```

**P0-P3 通用增问（可选）：**

```
Q7. 嫌疑 commit 区间？(git log 过/git bisect 候选)
Q8. Initial hypothesis？
```

### 产出

总是产出两个：

#### 1. `.ai/tasks/<YYYY-MM-DD>-bug-<slug>.md`

```markdown
# Bug: <Q1 答案>

## Severity
<Q2>

## Reproduction
<Q3>

## Expected vs Actual
- Expected: <Q4.expected>
- Actual: <Q4.actual>

## When did it start
<Q5>

## Suspect range
<Q7，如有>

## Initial hypothesis
<Q8，如有>

## Acceptance Criteria
- [ ] 回归测试：复现脚本 / 单测能在 patch 前 fail、patch 后 pass
- [ ] 测试名 / docstring 含 bug 编号 (RV-YYYYMMDD-NN) 方便日后 grep
- [ ] 该测试加入常规 CI
- [ ] root cause 在 finding 中明确写明（不能只写"修了"）

## Scope
- Repo: <由 Q3/Q5 推断；不确定标 TBD>

## Tests
<commands ；TBD by implementer>

## Review checklist
- [ ] 回归测试有效（临时 revert patch 后测试 fail）
- [ ] 改动在 root cause 范围内，无"顺手 refactor"
- [ ] review.md finding 状态翻 verified（由 reporter 而非修复人翻）
```

#### 2. `.ai/review.md` 追加 finding

```markdown
### RV-<YYYYMMDD>-<NN>: <Q1 答案>

- Severity: <Q2>
- Reporter: <用户 / 监控告警 / 用户提供>
- Owner: TBD（待分配）
- Verifier: <Reporter>
- Repo: <Q3 推断>
- File/symbol: TBD（OC 摸排后填）
- Status: open
- Finding: <Q4 actual + Q3 复现>
- Expected fix: <Q6 决定的策略：minimal / refactor / defer，未问则 TBD>
- Verification: 见 task 文件 Acceptance Criteria 第 1-3 条
```

### 下一步建议

| 严重度 + 紧急通道 | 建议 |
| --- | --- |
| P0/P1 + 走紧急通道 | 直接喂 Codex `03-codex-implement.md` 实施 hotfix；事后 24h 内补 ADR |
| P0/P1 + 不走紧急通道 | 喂 OC `01-opencode-context.md`（含复现）→ Claude 决策修复策略 |
| P2/P3 | 同上但优先级低，可批量处理 |

---

## §C · Bootstrap Intake（新项目）

### 问题流

```
Q1. 项目名 / 一句话定位？
Q2. 主要 repo 路径？
    （绝对路径；多个用换行分隔）
Q3. 技术栈？
    （Go / TypeScript / Node / Python / Java / C++ / Kotlin / Rust / 其它）
Q4. 团队规模？
    A. 个人项目
    B. 小团队 (2-5)
    C. 多团队协作
Q5. 已知 sharp edges？
    （语言坑 / 特殊约定 / 历史包袱 / 已踩过的坑；不知道写"待发现"）
Q6. Agent 协作配置？
    A. 与 starter kit 默认一致 (Claude 决策 + Codex 实施 + OpenCode 摸排)
    B. 自定义（请描述）
Q7. 是否有 GitNexus index / CI / 其它已有工具链？
    （列出，便于 AGENTS.md 适配）
```

### 产出

#### 1. `.ai/decisions.md` 追加 ADR

```markdown
## ADR-<YYYYMMDD>-01: 采用多 Agent 协同框架（<Q1 项目名>）

- Status: accepted
- Owner: <human>
- Date: <YYYY-MM-DD>
- Repos affected: <Q2>
- Context: 新项目 <Q1> 启动，引入多 Agent 协同框架。
- Decision:
  - 角色配置：<Q6 答案>
  - 任务 ≥ 2 小时工作量者必走 task 文件 + 三阶段流水
  - 工作目录与日志统一在 .ai/，源码在 <Q2>
- Alternatives considered: 单 Agent 全包；不引入框架。
- Consequences:
  - 成本：约一次 Claude bootstrap session（30-45 分钟）+ 持续轻量维护
  - 收益：跨 Agent 状态可追溯、token 消耗可控、scope 不易飘
- Follow-up:
  - 完成首批 sharp edges 收集后回来更新 AGENTS.md
  - 跑完第一个真实任务后复盘是否需要调整角色边界
```

#### 2. Claude bootstrap session prompt（让人粘到 Claude）

```text
你是 Claude Code。本次任务为新项目 <Q1> bootstrap 协作框架。

仓库：
<Q2>

技术栈：<Q3>

已知信息：
- 团队规模: <Q4>
- 已踩坑: <Q5>
- Agent 配置: <Q6>
- 已有工具链: <Q7>

操作：
1. 读 <Q2> 各仓的 README、package.json/go.mod/Cargo.toml 等顶层元数据
2. 用 ls / find 探查目录结构，不要读源码细节
3. 输出三份草稿到对应路径：
   - <PROJECT>/.ai/context.md
   - <PROJECT>/.ai/architecture.md
   - <PROJECT>/AGENTS.md（在 starter 模板基础上填实，保留 Tech Stack/Build/Sharp Edges 框架）
4. 输出每份的最终内容，由人审后再提交
5. 单次会话内完成，不切片

不要：
- 扫源码细节
- 编造未读到的项目细节
- 复述 starter kit 中已经存在的普适约束（读者已经读过）
```

### 下一步建议

按 `.ai/getting-started.md > §1` 第 4-5 步：跑 Claude bootstrap session → 人审。

---

## §D · Triage-only（只想 triage 已有想法的规模）

不产出文件。问 §A 的 Q1 + Q2.F1-F4，给路由建议：

```
你的任务规模评估：<Tiny/Small/Medium/Large/Epic>
建议入口：<对应路由>
建议跑哪些 prompt：<列表>

详细路由表见 .ai/getting-started.md §2。
```

---

## 通用纪律（所有分支）

1. **答案不全不强行往下走**——关键题（Q1/Q2/Q3）缺了，停下让用户补完再说。
2. **草稿先口述再落盘**——对用户预演一遍输出文件的关键段，得到 ✓ 才写文件。
3. **TBD 比错填好**——拿不准的字段写 `TBD`，不要瞎填。
4. **写完文件返回路径**——明确告诉用户文件落在哪，下一步喂哪个 prompt。
5. **不接管下一步**——intake 只负责"启动"，正式实施由对应 prompt 接管。
