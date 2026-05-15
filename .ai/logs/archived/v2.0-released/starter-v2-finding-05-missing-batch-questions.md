---
finding: starter-v2-finding-05
slug: missing-batch-questions
date: 2026-05-13
severity: P1
---

# Finding 05 — intake §A 缺少批处理域关键问题

## 现象

intake §A Task Intake 的 Q1-Q7 问题集是通用的，全部围绕：
目标 / 规模 / 涉及模块 / 范围 / 完成样子 / 约束 / 初始想法。

对批处理型 Epic，以下关键问题一个都没问出来：

1. **调度触发策略**：任务是 cron 定时触发、API 手动触发、还是两路？
2. **幂等保证机制**：重跑策略是什么？（truncate-rewrite / upsert / skip-if-exists？）
3. **大批量数据策略**：流式读取 vs 分页 vs 全量加载？内存边界？
4. **性能目标**：吞吐量 / 时限是多少？（本项目是「1000w 笔 30 min」）
5. **失败恢复**：任务中途失败如何处理？（retry / checkpoint / 告警？）

这些字段最终通过读 context.md 补全，但 intake 流程本身没有问出。

## 影响

- 若项目没有写好 context.md（典型：从零启动的新项目），这些字段会是空的
- 02-claude-plan.md 收到的 task brief 缺失批处理约束 → Claude 自行推断 → ADR 可能遗漏核心决策
- 比如：「幂等策略 = truncate-rewrite」是一个重要 ADR 决策，但 intake 没问出，
  导致它没有进入正式 ADR，只是 task brief 的一个字段

## 建议

在 `intake-templates.md > §A Task Intake` 的 Q6（已知约束）下方，
增加一个「领域类型探针」问题（**Q6.Batch，只在 Q2 ≥ Large 时触发**）：

```
Q6.Batch（仅当有批量数据处理时）：
  a. 触发方式？（定时 / API / 事件驱动 / 混合）
  b. 幂等策略？（truncate-rewrite / upsert / skip-if-exists）
  c. 数据量级？（行数量级 + 时限要求）
  d. 失败恢复？（retry / checkpoint / 告警 + 人工重跑）
```

这 4 个子问题可以一次性问，不违反「每次只问 1 题」原则（它们是一个问题的子字段）。

## 严重度

P1 — 明显摩擦。批处理域的核心约束（幂等/调度/性能）是架构决策的直接输入，
漏问直接降低 02-claude-plan 的质量。
这是 "starter 假设 web HTTP 为主" 对批处理域的典型盲点。
