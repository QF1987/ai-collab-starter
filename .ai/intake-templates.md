# Intake Templates

> 任务/Bug/Bootstrap 启动前的结构化提问模板。问题库 + 产出格式的**单一来源**。
>
> 两个访问入口共用本文件：
> - `.claude/skills/intake/SKILL.md`（Claude Code 自动 skill，UX 最优）
> - 任何 Agent 手动调用（Scout / Impl 把本文件当 prompt 直接读）
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
  C. context.md 已就绪 —— 项目 brief 已在 .ai/context.md 完整记录，
                          agent 从文件提取字段、补推断、用户只审 [待确认] 部分。
                          适合「设计文档已沉淀，跳过散文输入」。
```

**三种模式的产出**：完全相同（同一份 brief / task / ADR），只是收集人答案的方式不同。

> **探索式有一个变体 · Agent 全权设计**：当用户**明确授权** agent 拍板（典型话术：「你自己设计就行」/「按经验拍板」/「细节我不管」），走 `§A · 探索式工作流` 但**第 2 步 agent 试填**的字段 80-95% 标 `[agent-decision]`，仅保留 1-2 处真正不能瞎拍的（典型：技术栈选型、scope 边界、有无写操作）为 `[待确认]`。用户审核成本降低，但 `[agent-decision]` 透明化纪律不变。详见 `.claude/skills/intake/SKILL.md > 探索式 · Agent 全权设计变体`。

> **C 模式自动触发**：若 agent 启动 intake 时检测到 `.ai/context.md` 存在且包含核心字段（What/Why/Boundaries/AC/Constraints 至少 3 项），可主动建议「检测到 context.md 已就绪，建议走 C 模式」，由用户确认。用户也可以显式说「按 context.md 走」直接进入 C。

### A · 探索式 intake 工作流（推荐）

1. **第 1 步 · 散文输入**：
   - **默认**：agent 让人输入 1-3 句话描述「想做什么 + 为什么」。
   - **C 模式分支**：若 `.ai/context.md` 已存在且包含核心字段（What/Why/Boundaries/AC/Constraints 至少 3 项），跳过散文输入；agent 以 `context.md` 文件内容作为「原话」基础，直接进入第 2 步试填。
2. **第 2 步 · agent 试填**：agent 解析散文（或 context.md）+ 推断 + 试填全部字段：
   - 用人原话 / context.md 文件能直接抽到的内容 → 标记 `[原话]` 前缀（C 模式下来自 context.md 的内容也归此）
   - agent 推断补充的内容 → 标记 `[推断]` 前缀 + 一句话说推断理由
   - agent 在用户授权下拍板的内容 → 标记 `[agent-decision]` 前缀 + 决策理由（仅 Agent 全权设计变体使用）
   - 不确定 / 没信息支撑的字段 → 标记 `[待确认]` 前缀
3. **第 3 步 · 整体口述**：agent 把试填的 brief 整段口述给人，明显标识四类来源。
4. **第 4 步 · 人审核**：人逐字段反馈（"对" / "改成 X" / "我不知道留 TBD"）。
5. **第 5 步 · 迭代或落盘**：
   - 人说 "继续改" → 回到 第 2 步用新输入重试（**最多迭代 3 轮**）
   - 人说 "go" → 落盘
   - 超过 3 轮还没收敛 → **自动转问答式**（说明需求本身没想清，需要精确化）

### 探索式标识纪律（硬约束）

agent 在每个 brief 字段开头**必须**显式标四类前缀之一：

```markdown
## What
[原话] 标准化 release 状态机与错误码
[推断] 当前 status 字段是字符串拼凑、跨语言无统一来源（推断理由：用户说"标准化"暗含
       当前不标准；具体非标程度待 Scout 摸排确认）
[agent-decision] ORM 选 MyBatis 3.x（用户授权"你定"；理由：批处理 FULL OUTER JOIN
                  在 JPA 不友好，且 1000w 行批量 INSERT 需 SQL 透明）
[待确认] 是否同时定义 ErrorCode？brief 只提了状态机，未明确包含错误码
```

四类前缀含义：

- `[原话]` —— 用户口述 / context.md 文件直接抽取
- `[推断]` —— agent 自行推断，**必须**附理由；用户审时校对
- `[agent-decision]` —— 用户授权下 agent 拍板（典型话术「你定」「随便」「我不懂」）；
                        agent **必须**写决策理由 + 标 Owner 为 `Claude (intake)`；
                        进入 decisions.md 成为 ADR
- `[待确认]` —— 信息不足，agent 主动留空

不允许：

- 字段开头**没有**前缀标记
- 把推断内容标成 `[原话]`（虚假权威）
- 把 agent 拍板标成 `[原话]`（绕过用户授权）
- 把不确定标成 `[推断]`（佯装有理）

**技术选型类问题的处理**（如 ORM/框架/调度器/协议选择）：
- 若用户回答 "你定" / "随便" / "帮我选" / "我不懂" → 直接标 `[agent-decision]` + 给推荐 + 理由
- **不要**再回头追问用户确认（既然已授权）
- ADR 落盘时 Owner 字段写 `Claude (intake)`

人审时看到 `[推断]` / `[agent-decision]` / `[待确认]` 段就知道哪里要重点核对。

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

**Q6.Batch · 批处理域探针**（仅当涉及大批量数据处理 / 定时任务 / ETL 时触发；
agent 从 Q1/Q3 关键词推断，如 "对账"、"清算"、"批量导入"、"ETL"、"任务调度"、"日终"
等命中其一即问）：

```
Q6.Batch.1 触发方式？（定时 cron / API 主动触发 / 事件驱动 / 混合）
Q6.Batch.2 幂等策略？（truncate-rewrite / upsert / skip-if-exists / append-only）
Q6.Batch.3 数据量级 + 时限？（量级 + 完成时限，例：1000w 笔 / 30 min）
Q6.Batch.4 失败恢复策略？（auto-retry / checkpoint 续跑 / 告警 + 人工重跑）
```

这 4 个子问题一次性问完（用户体验：单次回答即可），不违反「每次只问 1 题」原则。
回答进入 task brief 的 `Batch Strategy` 段 + `Performance Target` 段。
**遗漏这些字段会让 02-claude-plan 的 ADR 缺核心决策依据**（典型：幂等策略未问出
会让 Impl 自由发挥成 per-row upsert，破坏 ADR 三段式幂等承诺）。

**Q8 · 扩展性骨架探针**（仅当 Q2 = Large / Epic 时问；
对单一 small/medium task 不问，避免过度设计）：

```
Q8. 本 Epic 是否预设了供后续 Epic 扩展的接口 / 插件 / SPI 骨架？

    A. 有 —— 描述（例：多渠道适配器、多协议解析器、策略模式 hook 点、gRPC 服务签名）
    B. 没有 —— 单一实现，未来不计划扩展
    C. 不确定 —— agent 帮我判断（按 Q1/Q3/Q5 关键词检测 multi-* / pluggable 信号）
```

若 A：task brief 的 `In-scope` 段**必须**包含「骨架定义 + 1 个实现」，
确保后续 Epic 扩展时不改骨架。SPI 接口签名变更未来需 ADR 锁定。

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
直接喂 03-implement.md 给 Impl，或人工实施。
```

下一步建议：直接喂 Impl `03-implement.md`。

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

- Medium：喂 Scout `01-context.md` + 这份 brief
- Large：同 Medium，注明「需 Claude 切片 ≤ 3 个 slice」

#### Epic

产出独立文件 `.ai/tasks/<epic-id>-<slug>.md`（不再追加 `plan.md`；plan.md 仅作路线图索引）。
`<epic-id>` 形如 `E1` / `M2-A`，`<slug>` 简短英文。

```markdown
# Task: <Q1 答案>（Epic <epic-id>）

> 本文件是 `/intake` skill 产出的 Epic task brief。
> 下一步：喂给 `02-claude-plan.md` 进行架构决策 + 切片。

## Goal
<一句话核心目标，由 Q1 + Q5 合成>

## Why
<为什么现在做；如未问就标 TODO>

## Scope

### In-scope
<Q4 in-scope，逐项；Q8=A 时此处包含「SPI 骨架 + 1 实现」>

### Out-of-scope
<Q4 out-of-scope，逐项；明确**当前 Epic 不做**的；后续 Epic 列在路线图>

## Batch Strategy（若 Q6.Batch 问过）
| 项 | 决策 |
|----|------|
| 触发方式 | <Q6.Batch.1> |
| 幂等策略 | <Q6.Batch.2> |
| 调度框架 | <Q6/Q7 推断；如未提及标 TBD> |
| 重跑机制 | <Q6.Batch.2 派生> |

## Performance Target（若 Q6.Batch.3 问过）
| 指标 | 要求 |
|------|------|
| 吞吐 | <Q6.Batch.3 量级 + 时限> |
| 失败恢复 | <Q6.Batch.4> |

## Acceptance Criteria（Epic-level）
1. <最小可验收点 1，由 Q5 派生 + 量化>
2. <可验收点 2>
3. ...
（每条 AC 必须对应一个或多个测试用例 / 真机步骤）

## Key Decisions（已 accepted ADR + 待决候选）
| ADR | 主题 | 状态 |
|-----|------|------|
| ADR-... | <intake 阶段已决的拍板项；标 `[agent-decision]` 来源> | accepted |
| TBD | <02-claude-plan 阶段需决议的开放问题> | proposed |

## Test Strategy
| 层 | 工具 | 覆盖目标 |
|----|------|---------|
| 单元 | <例：JUnit + Mockito> | <算法分支 / pure function> |
| 集成 | <例：Testcontainers> | <DB / 外部资源> |
| E2E | <例：MockMvc / Browser> | <端到端 happy path + 关键失败路径> |

## Extensibility（若 Q8 = A）
- SPI 接口名 + 关键方法签名：<列出>
- 当前 Epic 提供的实现：<例：单一 channel>
- 后续 Epic 扩展时**不许**改 SPI 签名（变更需 ADR 锁定）

## Known Constraints
<Q6 答案 + 技术栈具体版本（语言 / 框架 / DB / CI 等）>

## Initial Thoughts
<Q7 答案，如有>

## Proposed Slices（供 02-claude-plan 决策参考）
| Slice | 内容 | 主要产出 |
|-------|------|---------|
| 1 | <例：DB 层> | <DDL + entity + mapper stub + 测试 fixture> |
| 2 | <例：领域适配器> | <SPI 实现 + 单元测试> |
| 3 | ... | ... |

> 实际切片数 + 边界由 02-claude-plan 阶段最终决定（推荐 3-5 片，
> Web 全栈 Epic 通常 3 片，批处理 / 多层后端 Epic 可到 4-5 片，
> 单片 PR diff 应控制在 300-500 行内）。

## Handoff State
下一步：喂 `02-claude-plan.md` 给 Claude Code，输入文件：
- `.ai/context.md`
- 本文件（`.ai/tasks/<epic-id>-<slug>.md`）
- `.ai/decisions.md`
```

**强约束 · AC ↔ Scope 校验**：intake 落盘前 agent 必须自检——**Acceptance Criteria 段
提到的每个文件 / 模块 / 命令行参数**都必须出现在 `In-scope` 或 `Out-of-scope` 或
`Known Constraints` 段；若不一致，说明 AC 写过细 or scope 漏字段，停下让用户补完
再落盘。这是为了避免 03-implement 阶段 Impl 因「AC 要求改 X 但 X 不在 scope」
触发 scope-deviation。

下一步建议：人审 epic brief → 喂 Scout `01-context.md` 启动调研（或
若 Q8=A，直接进 02-claude-plan 切片）。

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
    紧急通道允许：跳 Step 1 Scout packet（人直接写 task）+ 跳 Step 2 ADR（先 hotfix 后补）
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
- File/symbol: TBD（Scout 摸排后填）
- Status: open
- Finding: <Q4 actual + Q3 复现>
- Expected fix: <Q6 决定的策略：minimal / refactor / defer，未问则 TBD>
- Verification: 见 task 文件 Acceptance Criteria 第 1-3 条
```

### 下一步建议

| 严重度 + 紧急通道 | 建议 |
| --- | --- |
| P0/P1 + 走紧急通道 | 直接喂 Impl `03-implement.md` 实施 hotfix；事后 24h 内补 ADR |
| P0/P1 + 不走紧急通道 | 喂 Scout `01-context.md`（含复现）→ Claude 决策修复策略 |
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
    A. 与 starter kit 默认一致 (Claude 决策 + Impl 实施 + Scout 摸排)
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
