---
finding: starter-v2-finding-04
slug: epic-output-format-too-minimal
date: 2026-05-13
severity: P1
---

# Finding 04 — intake Epic 产出格式过于简陋 + 落盘路径与用户期望不符

## 现象

`intake-templates.md > §A Epic 产出格式` 指定：
> "产出 `.ai/plan.md` 的 epic 章节草稿（追加，不覆盖）"
> 格式仅含：目标/估时/子任务(TBD)/已知约束/初始想法 5 个字段

两个问题：

1. **落盘路径不对**：用户期望一个独立 task brief 文件（`.ai/tasks/E1-*.md`），
   而不是往 plan.md 追加一段。plan.md 是 epic 路线图视角，
   tasks/*.md 才是各 slice/epic 的工作文件。
   两者语义不同，但 intake 只知道 plan.md。

2. **格式过于简陋**：5 个字段（目标/估时/子任务(TBD)/约束/想法）无法承载：
   - 验收标准（每个 slice 的 done 条件）
   - 关键 ADR 决策（ORM、调度框架、幂等策略等）
   - 域模型草图
   - 测试策略（单元/集成/E2E 分层）
   对于 Java/批处理 Epic，这些字段是 02-claude-plan 的必要输入。
   用 5 字段 brief 喂 Claude Plan 会导致架构决策缺乏基础。

## 影响

- Agent 实际产出比 intake 规定更丰富（自行扩展），但扩展内容没有模板约束 → 各 epic 格式不一致
- 下游 02-claude-plan.md 缺少"已知约束/验收标准"输入，导致 Claude 需要二次追问

## 建议

在 intake-templates.md 的 Epic 产出段里：

1. **改落盘路径**：从 `.ai/plan.md` 追加 → 独立文件 `.ai/tasks/<epic-id>-<slug>.md`
   （plan.md 只保留路由表/路线图，不作为内容主体）

2. **扩展 Epic 模板**，在 5 个现有字段基础上增加：
   ```markdown
   ## Acceptance Criteria (Epic-level)
   <每个 slice 的完成条件；由 intake 问 Q5 填充>
   
   ## Key decisions to make (pre-plan)
   <ORM/框架/调度策略等，标明 [需 ADR] 或 [intake 已决]>
   
   ## Test strategy
   <单元/集成/E2E 分层；批处理域特别要写 Testcontainers 策略>
   ```

3. 对于批处理 Epic，增加两个专属字段：
   - `Batch strategy`：调度触发方式（定时/API 触发）、幂等策略、重跑机制
   - `Performance target`：数量级 + 时限（e.g., 1000w 笔 30 min）

## 严重度

P1 — 明显摩擦。Epic 是最大的 intake 输入规模，格式最简陋的地方出现在最需要信息的地方。
这是 "starter 假设 Epic = 多个 Small task 的集合" 而非 "独立复杂域" 的隐藏偏见。
