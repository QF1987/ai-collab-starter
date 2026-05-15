---
finding: starter-v2-finding-01
slug: intake-mode-missing-context-ready
date: 2026-05-13
severity: P2
---

# Finding 01 — intake Q-1 缺少「context 已就绪」模式

## 现象

`/intake` skill 的第 -1 步（模式选择）只提供三个选项：
- 探索式（推荐）
- 探索式 · Agent 全权设计
- 问答式（精确版）

本项目已在 `.ai/context.md` 中沉淀了完整的项目 brief，包含 What / Why / Boundaries /
Acceptance Criteria / Constraints 五要素，比"1-3 句散文"丰富数倍。

探索式第 1 步要求"agent 让人输入 1-3 句话描述"——与项目已有完整 context.md 的现实脱节。

## 影响

- 用户要么重复输入（已在 context.md 里写过的内容再口述一遍），
- 要么 agent 跳过散文输入直接读 context.md（不符合 skill 设计，有歧义）。
- 导致探索式流程第 1 步产生无谓摩擦，或 agent 自行解释 scope 而无人确认。

## 建议

在 Q-1 增加第四个选项：

```
- label: "context.md 已就绪（直接确认 + 落盘）"
  description: "项目 brief 已在 .ai/context.md 中完整记录 → agent 从文件提取字段 → 用户只审 [待确认] 部分"
```

并在 intake-templates.md 增加对应工作流：
1. agent 读 context.md / brief 文件
2. 直接走「试填全部字段」（80-95% [原话]，剩余 [推断]/[待确认]）
3. 口述摘要 → 用户确认 → 落盘

本质上是「Agent 全权设计变体」的 input 来自文件而非口述。

## 严重度

P2 — 轻微瑕疵，不阻塞流程，但增加冗余交互成本，在文档驱动型项目（如本项目）中尤为明显。
