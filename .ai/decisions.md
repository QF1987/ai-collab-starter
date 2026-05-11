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
4. **数据契约约束分三级**（如涉及 schema / DB）——列语义级 / 表结构级 / 数据级，禁止一句话混并。

## Standing Decisions

> 长期生效的纪律性 ADR（如团队工作模式、Agent 角色分工等）应当列在这里。
> 单次任务的具体决策依次追加在下方。

<!-- TODO bootstrap 时由 Claude 写第一个 ADR：项目采用本协同框架 -->
