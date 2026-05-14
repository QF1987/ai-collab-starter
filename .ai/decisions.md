# Decisions

Record decisions that should survive individual AI sessions.

## Decision Format

每条决策用 ADR（Architecture Decision Record）格式。ADR 编号：`ADR-YYYYMMDD-NN`（同日多个决策递增 NN）。

```markdown
## ADR-YYYYMMDD-NN: <title>

- Status: proposed | accepted | superseded | rejected
- Owner: <human / Claude / Codex / OC>
- Date: YYYY-MM-DD
- Repos affected: <list>
- Context: <为什么需要这个决策、当前现状>
- Decision: <唯一具体实现选择；禁用「或」「让 X 决定」等模糊表述>
- Alternatives considered: <至少列 1 个被拒方案 + 拒绝理由>
- Consequences:
  ### Positive consequences
  - <收益 / 解锁能力 / 简化点>
  ### Negative consequences
  - <至少 1 项被牺牲的能力 / 新增依赖 / 兼容性窗口；禁止留空>
- Follow-up: <后续任务 / 验证条件 / 相关 task 文件>
```

### 强约束（详见 `.ai/prompts/02-claude-plan.md`）

1. **决策必须唯一具体**——禁「或」「让 Codex 决定」「视情况而定」。下游 Agent 看到 `Decision` 段必须能照着一条路走。
2. **Alternatives considered 段不可省**——至少列 1 个被拒方案。这是回看时 trace 决策动机的关键。
3. **Negative consequences 段不可留空**——每个决策都有代价，想不出说明你没认真评估。
4. **数据契约约束分级**（如涉及 schema / DB）：
   - **L1 列语义级** —— 某列的值含义、取值集合、枚举约束
   - **L2 表结构级** —— 不删除现有列、不破坏现有约束；新增列须 IF NOT EXISTS
   - **L3 数据级** —— 数据迁移 / backfill / 重跑策略
   - **L4 实体注解级**（Java/MyBatis/JPA 等 ORM 生态适用）—— Java entity 字段 ↔ DB 列映射（`@Results`/`resultMap`/`@Column`）；禁止跨 Slice 单方面改 entity 字段名而不同步改 ORM 映射，等效于改调用者 API
   - **L5 Mapper / Repository 接口级**（同 L4 适用范围）—— Mapper/Repository Java 接口的方法签名是 Service 层的调用合约；新增方法不破坏已有调用；改方法参数/返回类型须在 ADR 中声明，与 L2 不兼容改动同等对待

   **何时用 L4/L5**：项目语言 = Java/Kotlin + ORM 框架（MyBatis/JPA/Hibernate）时，单纯 L1-L3 不能覆盖 entity ↔ DB 之间的中间层风险，需补 L4/L5。Go/Rust/TS 项目通常不需要这两级（schema 与代码距离更近）。

## Standing Decisions

> 长期生效的纪律性 ADR（如团队工作模式、Agent 角色分工等）应当列在这里。
> 单次任务的具体决策依次追加在下方。

<!-- TODO bootstrap 时由 Claude 写第一个 ADR：项目采用本协同框架 -->
