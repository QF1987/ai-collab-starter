---
finding: starter-v2-finding-07
slug: state-summary-vs-logs-mismatch
date: 2026-05-13
severity: P2
---

# Finding 07 — state.md 摘要字段与 logs/ 实际产出不一致

## 现象

intake 跑完后,state.md `Last completed step.产出` 段写:

> `.ai/logs/starter-v2-finding-01~04.md`(元观察 4 条)

但实际 `.ai/logs/` 目录下存在 **6 条** finding 文件(01-06)。

推断成因:Agent 在写到第 4 条 finding 时刷了一次 state.md,
之后又补写了 05/06 两条 finding,但没有回头同步更新 state.md 的摘要字段。

## 影响

- **下一个 Agent / 人读 state.md 会被误导**:以为只有 4 条 finding,
  可能漏读 05/06(批处理域问题 + SPI 扩展问题这两条最值钱的发现)
- **starter v2.0 升级门槛进度评估失真**:门槛要求"≥ 5 条改进项",
  state.md 显示 4 条 → 看似未达成,实际已达成
- **元观察记录与主流程的同步纪律没有明文规定**——Agent 边干活边记日志,
  state.md 摘要的"最新性"靠 Agent 自觉

## 建议

在 `.ai/prompts/` 的所有 prompt 模板(尤其 intake skill 和 04-opencode-review)
的「收尾纪律」段,增加一条:

```
state.md 刷新必须发生在所有产出文件 commit/write 完成之后,
不允许"分阶段刷 state"。如果在写过程中已经预填了 state,
最后一步必须重新扫一遍 .ai/logs/ 和 .ai/tasks/ 目录,
确保 state.md 引用的文件路径/数量与实际一致。
```

或者更简单的工程化方案:**state.md 不再手写"产出文件清单",
而是写"产出根目录"**,例如:

```markdown
- 产出: `.ai/logs/starter-v2-finding-*.md`(数量请 `ls` 实查)
```

这样从根上避免"摘要滞后于实际"的脱节。

## 严重度

P2 — 不阻塞,但**信号失真**会导致门槛评估误判,在自动化决策链路(如脚本读 state
判断是否升级 starter)中可能放大成 P1。建议作为 v2.0 必修。
