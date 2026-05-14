# Changelog

All notable changes to **ai-collab-starter** are documented here.

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html):
- **MAJOR** version when breaking changes to the workflow contract (prompts removed/merged, file paths renamed)
- **MINOR** version when adding capabilities backwards-compatibly
- **PATCH** version when fixing typos / wording / non-structural improvements

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
