# Changelog

All notable changes to **ai-collab-starter** are documented here.

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html):
- **MAJOR** version when breaking changes to the workflow contract (prompts removed/merged, file paths renamed)
- **MINOR** version when adding capabilities backwards-compatibly
- **PATCH** version when fixing typos / wording / non-structural improvements

---

## [v4.0.0-rc1] — 2026-05-15

> ⚠️ **Release candidate · 待实战 dogfood 验证后翻 stable**
>
> 本版本是从 v3.0 实战 + 两个 meta-design 讨论(触发机制 / 跨 session 演化)推导而来,
> **0 实战 dogfood**。derived 项目默认仍 sync v3.0.0 stable,本 rc 留作 starter 自身实验。
> 下次 epic 跑通后,若信号良好 → 翻 v4.0.0 stable;若撞坑 → 退回 v3.0.0 出 rc2。

### TL;DR

为 starter 加 **跨 session 自演化基础设施 + 多源 review 触发机制 + 升级仪式文档化**。
解决两个结构性盲点:

1. **跨 session findings 失联**:v3.0 之前 finding 散在各 derived 项目本地 `.ai/logs/`,
   starter 自己看不到。新 session 的 Claude 没法知道有多少待实施。
2. **演化纯被动**:v2.0/v3.0 升级都靠 Human 显式触发。Claude 不主动监控阈值,
   findings 容易积压被遗忘。

**无 breaking change**(v4.0 完全向后兼容 v3.0 工作流契约)。

### Added · 基础设施层

#### `ai-collab-starter/VERSION`(新)
- 单行文件存当前 release 版本(如 `v3.0.0`)
- 任意脚本 / Claude session 都可 `cat` 读取

#### `.ai/logs/pending-findings/` + `.ai/logs/archived/`(新)
- 跨项目 finding 汇聚 inbox(`from-<project-name>/` 分桶)
- 已实施 finding 按 release 归档(`v2.0-released/` / `v3.0-released/`)
- 22 历史 findings 已 backfill 进 inbox(2 deferred + 17 v2.0 + 3 v3.0)
- `.ai/logs/README.md` 解释 inbox 约定 + 双写规则

#### `scripts/starter-status.sh`(新)
- 任意项目跑,输出:starter VERSION + project STARTER_VERSION drift 检测 + inbox pending count + 升级触发评估
- 支持 P0/P1 finding 强警告

#### `scripts/sync-finding.sh`(新)
- 帮助 derived 项目把 finding 同步到 starter inbox
- 自动识别 project name(git remote / pwd basename)
- 阈值告警 ≥ 5 时提醒升级

#### `derived-project/.ai/STARTER_VERSION` stamp 约定(新)
- 每个 derived 项目 stamp 一行 `vX.Y.Z · synced YYYY-MM-DD`
- `starter-status.sh` 用此 stamp 与 starter VERSION 比对检测 drift

### Added · 机制层

#### `.ai/prompts/02-claude-plan.md`
- **Task brief frontmatter 约定**(`claude-review-required: false | auto | required`)
- **多源触发清单表**(4 类:Pre-declared / Codex self-flag / OC escalation / Auto-P0-P1)
- 何时 Claude 02-plan 应主动声明 `required` 的标准

#### `.ai/prompts/03-codex-implement.md`
- **Codex self-flag 路径**:实施期发现架构敏感时,主动在 progress.md 记 `self-flag(Codex):`,
  并刷 state.md `Next step.Agent = Claude` + `触发来源 = B`

#### `.ai/prompts/04-opencode-review.md`
- **Escalation 判定表 C1-C7**(机器化):7 条机器可判定条件 + grep / count 方法
- 与触发来源 A(预声明)/ B(self-flag)的协同规则(已声明的跳过判定表)

#### `.ai/state.md` template
- 新增 `Next step.触发来源` + `Next step.触发条件` 字段
- 校验规则注释扩展为 v4.0 4 源(A/B/C/D)+ 原 v2.0 闸门

### Added · 入口层

#### `.ai/starter-upgrade-protocol.md`(新)
- starter 升级仪式 SoT,7-step 跨 session 可复现流程
- 触发条件清单 + SemVer 决策树 + rc 模式约定
- 任何 Claude session 跑此协议都一致(不依赖具体 session 上下文)

#### `.ai/getting-started.md`
- 新 §〇 段:**任何新 Claude session 启动前的检查清单**
- 决策矩阵:何时主动提醒 Human + 何时直接进业务
- Finding 落档双写约定(本地 + sync-finding.sh)

#### `AGENTS.md`
- 新增 "Claude 主动提醒升级 starter (v4.0)" 子段
- 5 类时机 + 应说什么 + 不该主动提醒的场景

### Why v4.0 而不是 v3.1 patch

最初考虑过只发 v3.1 patch(只做基础设施),但实际 backlog 包含的不只是基础设施:
- 多源触发机制(02/03/04 prompt 改动)是 v3.0 dogfood 后两个 meta-design 讨论的产物
- 升级仪式文档化是结构性新增
- 这些**新增了 minor 级能力**,不是 typo / wording 改进

按 SemVer:**MINOR**(向后兼容的新能力)。所以 v4.0.0(用 rc1 标记未 dogfood)。

### Validation status

| 类别 | 状态 |
|------|------|
| 基础设施(VERSION / stamps / scripts / inbox) | ✅ smoke 测过 |
| 机制层 prompts 改动 | ⏳ 待下个 epic 实战 |
| 升级仪式 protocol | ⏳ 待下次 starter 升级实战 |
| 整体 cross-session 检查清单 | ⏳ 待下次新 session 实战 |

**建议下一个 epic** 启动时:
1. 跑 `bash scripts/starter-status.sh` 验证检查清单工作
2. 在新 task brief 实验 `claude-review-required` frontmatter
3. 若 Codex 实施期撞到架构问题,尝试 self-flag 路径
4. epic-closeout 后回顾 v4.0 这套机制是否真有用

实战信号良好 → tag `v4.0.0` stable;撞坑 → tag `v4.0.0-rc2` 修正后重试。

### 升级指南(rc 不强推,但 starter 自己已 stamp v4.0.0-rc1)

derived 项目**不需要**主动 sync。下次升级 v4.0 stable 时再统一 sync。
若想提前体验 rc:

```bash
rsync -av --exclude='.git' /path/to/ai-collab-starter/.ai/prompts/ .ai/prompts/
rsync -av /path/to/ai-collab-starter/.ai/{intake-templates,workflow,starter-upgrade-protocol,getting-started}.md .ai/
echo "v4.0.0-rc1  · synced $(date +%Y-%m-%d)" > .ai/STARTER_VERSION
```

---

## [v3.0.0] — 2026-05-15

### TL;DR

第二次升级,基于 starter v2.0 在 **DeviceOps**(Go backend + Kotlin Android client 多仓项目)上跑通
3 条 P1 follow-up task 的二轮 dogfood 实战,沉淀 5 条 finding 全部实施。

**无 breaking change**——v3.0 完全向后兼容 v2.0 的工作流契约;所有新增内容是**模板细化 + 约束加强**。
但有 1 条**约束新增可能违反 v2.0 当前实践**:Finding #21 要求 06-codex-fix 收尾 Next step **必须**指向 Reporter verify
而非 Human merge——v2.0 实践中有时 Codex 直接给 Human,v3.0 起这种走法只在 P3 + <10 行 fix 时允许。

### 实战数据(v2.0 dogfood 二轮)

3 条 P1 形态全跑过 + Finding 20 F-A "Small Task Shortcut" 适用边界由实战确立:

| Task | 复杂度 | Verdict | 三步法适配 |
|------|--------|---------|----------|
| P1 #1 ops-only(SQL sampling) | 等价路径完成 | reframed verified | N/A(非代码) |
| P1 #2 Small(+5/-2 行 Kotlin header) | PATCH → fix → verify | F-A 确认 over-engineered(三步法读起来像审 Epic) |
| P1 #3 small-Medium(+214 行 Go CLI + tests) | PASS 一次过 | **三步法回归正常使用** |

→ **Small Task Shortcut 适用边界**:≤30 行单文件无 ADR → 简化;30+ 行/跨决策 → 三步法正常。

### Added

#### `.ai/prompts/04-opencode-review.md`

- **Small Task Shortcut 段**(Finding #20 F-A):满足 ≤30 行 + 单文件 + 无架构敏感 + 无 ADR 条件时,
  跳过完整三步法,只做"Scope + AC + 测试证据 + 一条 grep 调用点"四步精简
- **第三步 Quality 改为 repo-自适应**(Finding #20 F-B):按改动语言/生态启用对应子项
  - Java/Kotlin + Spring:N+1 / 资源关闭 / 构造器 / lifecycle
  - Go:-race / context / Close / goroutine leak / error wrap (%w)
  - TS/JS:async/await 错误链 / null safety / 副作用清理
  - Rust / SQL / ops-shell:各有专属子项
  - 跨语言项目交集都跑,但**不**跑改动语言外的项(避免 false positive)

#### `.ai/prompts/03-codex-implement.md` + `04-opencode-review.md` + `06-codex-fix.md`

- **"下一步提示词"段 v3.0 指针版**(Finding #20 F-C):
  - prompt body 强制指针式 3 字段(`必读输入` / `Expected fix ID 或 AC 指针` / `验证命令`)
  - 显式禁止在 prompt body 内复述 task / review.md 已有内容
  - 若 prompt 仍想复述细节,改进 task / review 文件而非膨胀 prompt
  - 完成后动作硬限 ≤ 2 行

#### `.ai/prompts/06-codex-fix.md`

- **收尾纪律 · Reporter verify 必经路径**(Finding #21 强约束):
  - 06-fix 完成后 Next step **必须**指向 Reporter(OC 或 Claude),不能跳过到 Human
  - 例外:仅 P3 + <10 行 fix 可指 Human
  - P0/P1 finding 严禁跳过 Reporter verify,违反视为 RV 闭合无效

#### `.ai/prompts/02-claude-plan.md`

- **锁定新增符号名前 grep 同包预检**(Finding #22 强约束):
  - task brief 最终化前 Claude 必须对目标 package 跑同名符号 grep
  - 命中冲突 → 改名或重构(重构是独立新 task)
  - 禁止把"发现冲突"的责任推给 Codex 实施期
  - 配套 grep 命令示例(Go 函数 / 变量 / map key 三套)

### Why these 5 changes

**Finding 20 (3 子项)**:v2.0 三步法对所有规模 review 一刀切,实战发现 ≤30 行小任务过重;
F-A/B/C 三子项分别解决"规模分流 / 语言适配 / prompt 模板化"三个方向。

**Finding 21**:v2.0 workflow.md §5 关闭规则要 Reporter 翻 verified,但 06-codex-fix prompt 没强制
把 Next step 指向 Reporter。DeviceOps P1 #2 实战中 Codex 直接给 Human,虽然 P2 case 无害,
但 P0/P1 同样路径会违反硬约束。本 patch 消除制度缺口。

**Finding 22**:v2.0 task brief drafting 流程中,Claude 在锁定符号名前未做 grep 同包预检。
DeviceOps P1 #3 实战中 `uploadFile` 与 `release.go:543` 已有同名冲突,Codex 实施期才发现编译失败,
被迫改名 `uploadFileHTTPURL`。本 patch 把 grounding 校验提前到 Plan 阶段。

### Unchanged from v2.0

- 8-prompt 框架(01-08;05 在 v2.0 已删除,v3.0 不动)
- workflow.md §5 关闭规则 / Escalation 路径
- intake-templates.md(C 模式 / Q-Batch / Q8 SPI / Epic 模板等)
- decisions.md L1-L5 Data Contract 五级
- state.md 校验规则注释
- worktree 收尾协议

### 升级指南(v2.0 → v3.0)

无破坏性改动,直接拉新版即可。但**建议同步给已有项目的 .ai/**(用 rsync 或 cherry-pick 这 5 个文件):

```
.ai/prompts/02-claude-plan.md
.ai/prompts/03-codex-implement.md
.ai/prompts/04-opencode-review.md
.ai/prompts/06-codex-fix.md
```

无 schema 变更 / 无文件路径变更 / 无文件删除。CHANGELOG 与 README 自动覆盖。

### Validation

v3.0 内容尚未跑 dogfood 三轮验证。建议下一次启动新 epic / task 时优先使用 v3.0 prompts,
若发现 Small Task Shortcut 边界 / repo-自适应表 / 指针版 prompt body / Reporter verify 强约束 / brief grounding
任一条有缺口,记 starter-v4-finding-NN-*.md 候选。

---

## [v2.0.0] — 2026-05-14

### TL;DR

第一次大规模升级,基于在异构项目(Java/Spring Boot/PostgreSQL 的支付对账系统 PaymentRecon E1)
上跑完整一轮 4-Slice epic 的实战经验,沉淀 18 条 finding 并实施其中 16 条。

**Breaking change**:删除 `.ai/prompts/05-claude-review.md`(独立 step 合并入 04-review 的 escalation 路径)。
其余改动向后兼容。

### Added

- **`.ai/intake-templates.md`**
  - Q-1 新增第三种 intake 模式 `C. context.md 已就绪`(Finding #01)。检测到 context.md 包含核心字段时,Agent 主动建议跳过散文输入
  - 探索式标识纪律新增 `[agent-decision]` 前缀(Finding #03):用户授权"你定"时 Agent 拍板的字段必须显式标识 + 写决策理由
  - §A Q6.Batch 批处理域探针(Finding #05):4 子问题覆盖触发方式 / 幂等策略 / 数据量级时限 / 失败恢复
  - §A Q8 扩展性骨架探针(Finding #06):仅 Large/Epic 触发,捕获 SPI / 插件 / 适配器模式诉求
  - **Epic 产出格式重构**(Finding #04):
    - 落盘路径从 `.ai/plan.md` 追加段改为独立文件 `.ai/tasks/<epic-id>-<slug>.md`
    - 字段扩展:加 `Batch Strategy` / `Performance Target` / `Acceptance Criteria` / `Key Decisions` / `Test Strategy` / `Extensibility` / `Proposed Slices` 段
  - AC ↔ Scope.paths 强制校验(Finding #15):Epic brief 落盘前 Agent 自检 Acceptance Criteria 涉及的所有文件都在 paths 中

- **`.ai/workflow.md`**
  - §4 实现阶段强约束:03 完成后 `Next step` 必须接 `04-opencode-review`,不可跳到下一片 03(Finding #13)
  - §5 完全重写:**单 reviewer (OC) + escalation 路径**模式;删除"Claude review 独立步骤"概念(Finding #19 方案 B)
    - §5.1 OpenCode review 三步法:Scope / Architecture / Quality
    - §5.2 Escalation 路径:6 类触发条件,Claude 介入时作为 main session 协作者
    - §5.3 "内联跑了但没记录"禁止条款
  - §8 新增 Worktree convention(Finding #08 + #09):
    - §8.1 worktree 模式触发条件
    - §8.2 worktree 收尾约定(强制 rsync 回流 + state.md 警告行)
    - §8.3 `Next step` 在 worktree 中的额外纪律

- **`.ai/state.md`(template)**
  - `Next step` 段新增校验规则注释(Finding #13):自动判定 03 后必接 04
  - `Last completed step` 产出字段约定从"具体文件清单"改为"产出根目录 + (数量请 ls 实查)"(Finding #07)

- **`.ai/decisions.md`(template)**
  - 数据契约从三级扩展到五级(Finding #12):
    - L1 列语义级 / L2 表结构级 / L3 数据级(v1.0 已有)
    - **L4 实体注解级 + L5 Mapper/Repository 接口级**(Java/Kotlin + ORM 项目适用)

- **`.ai/prompts/02-claude-plan.md`**
  - "≤ 3 切片"放宽为"推荐 3-5 切片"(Finding #10),按 Web/批处理域分级建议;单片 PR diff 300-500 行
  - Compatibility 段补 L4/L5 数据契约约束(Finding #12)
  - 附带产出段补 **AC ↔ Scope.paths 校验**纪律(Finding #15)
  - 附带产出段补 **集成测试场景特别约定**(Finding #17):完整 `@SpringBootTest` 时必须预先纳入前序 Slice 可能需要 bean wiring 修复的文件

- **`.ai/prompts/03-codex-implement.md`**
  - Scope 强约束段(Finding #14):4 类越界场景的显式处理路径,例外仅限 ≤ 3 行 idiomatic 整理
  - 后端 E2E 证据要素(Finding #05 + #18 合并):fixture 映射 / HTTP 断言 / DB 断言 / Testcontainers 证据 四要素
  - 收尾段强制 `Next step` 接 04-review(Finding #13);例外仅在 task 标 `skip-review: true` 时

- **`.ai/prompts/04-opencode-review.md`**
  - Review 三步法(Finding #14):Scope 验证 → Architecture 对齐 → Quality 常规
  - Scope-deviation 处理路径:`Status: escalated` + state.md Next step 指向 Claude
  - "形式上用 ADR 工具但价值被实现吃光"类型识别(典型:cursor 一出来就 `.toList()`)
  - 引用 05-claude-review 的地方替换为 Claude escalation(无独立 prompt)

- **`.ai/prompts/06-codex-fix.md`**
  - Scope 强约束段(Finding #14):"顺手 refactor"诱惑处理路径
  - **epic-closeout 模式**(v2.0 新增):允许跨 slice 修多个 RV;OC verify 简化为"真修了 + 测试 PASS"

- **`.claude/skills/intake/SKILL.md`**
  - 第 5 步新增 Worktree 收尾(Finding #08 + #09)

- **`CHANGELOG.md`**(本文件,新增)

### Changed

- **`.ai/intake-templates.md`** §A 探索式 Step 1:`散文输入` 现支持"C 模式分支",当 context.md 已就绪时跳过散文,直接从文件抽取(Finding #02)

### Removed

- **`.ai/prompts/05-claude-review.md`**(Finding #19 方案 B,**Breaking change**)
  - 原因:E1 实战中 4 个 Slice + 3 轮 fix + 2 轮 verify 全过程 **05 从未作为独立 step 被调用**;Claude review 实际以 main session 协作者形式在 chat 内发生
  - 替代:OC review 三步法 + escalation 路径;触发条件归入 workflow.md §5.2
  - 影响:外部如果有项目脚本引用了 `.ai/prompts/05-claude-review.md`,需改为 `.ai/prompts/04-opencode-review.md` 的 escalation 分支

### Deferred to v2.1+

- **Finding #11**: 二组 paths 对 Java 多层结构不够(P3)— 仅 Java 项目相关,starter 语言中立,推迟到专题 v2.1
- **Finding #16**: Mockito inline 在 macOS 失败(P2)— 环境特定问题,通用建议太抽象,推迟到积累更多生态信号后

### Validation

本次升级基于 **PaymentRecon E1** 异构验证完成:

- 项目栈:Java 17 + Spring Boot 3 + PostgreSQL + Maven + MyBatis + Testcontainers(与 starter v1.0 验证的 Go/Vue/Web 栈完全异构)
- 业务域:聚合支付平台 T+1 单渠道对账子系统(金融批处理,与 v1.0 IoT/web 域异构)
- 规模:4 个 Slice + 1 个 epic-closeout 批次 + 9 条 RV finding(全部 verified 或 subsumed)+ 18 条 starter finding
- 测试:19/19 PASS(单元 + Testcontainers 集成 + MockMvc E2E)
- 工作流闸门:`Scope → Architecture → Quality` 三步法在 S2/S3/S4 三个连续 Slice 上表现一致

详细复盘见 `payment-recon-demo/.ai/logs/e1-validation-report.md`(独立项目)。

---

## [v1.0.0] — 2026-05-13

### Added

初始发布:基于 DeviceOps 项目 dogfood 沉淀的 8 prompt + intake skill + workflow 框架。

- 8 个 prompts(`01-opencode-context.md` ... `08-codex-audit.md`)
- `intake` skill(探索式 / 问答式 / Agent 全权设计)
- `workflow.md` 七阶段流程
- `state.md` / `progress.md` / `decisions.md` / `review.md` 协作产物模板
- `init-collab.sh` bootstrap 脚本

[v2.0.0]: https://github.com/<user>/ai-collab-starter/releases/tag/v2.0.0
[v1.0.0]: https://github.com/<user>/ai-collab-starter/releases/tag/v1.0.0
