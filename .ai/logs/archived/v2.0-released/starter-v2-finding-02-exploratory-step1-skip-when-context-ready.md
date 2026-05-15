---
finding: starter-v2-finding-02
slug: exploratory-step1-skip-when-context-ready
date: 2026-05-13
severity: P1
---

# Finding 02 — 探索式 Step 1「散文输入」与 context.md 已就绪冲突

## 现象

`intake-templates.md > §A 探索式 intake 工作流 第 1 步`：
> "agent 让人输入 1-3 句话描述「想做什么 + 为什么」"

本项目 `.ai/context.md` 已是一份完整的设计文档（2200+ 字），包含：
域模型、算法伪码、Epic 路线图、E1 范围明细、非功能约束等。

如果按流程让用户"输入 1-3 句散文"，会产生两个问题：
1. 用户被迫将已有完整文档压缩成 3 句话（信息严重损失）
2. Agent 随后试填时仍需读 context.md，"散文"这一步是白走

## 影响

- **P1 明显摩擦**：文档驱动型项目（设计先于编码）会在每次 /intake 时都踩这个坑
- Agent 实际会悄悄读 context.md 但不声明，导致 [原话] / [推断] 标识来源模糊

## 建议

在探索式 Step 1 增加分支：

```
if .ai/context.md 存在 AND 包含五要素:
  告知用户："检测到已有 context.md，将以文件为散文输入，跳过手工口述。"
  直接进入 Step 2 试填
else:
  正常请求用户输入 1-3 句散文
```

并在 intake-templates.md 的探索式工作流里写明这个分支（一行说明即可）。

## 严重度

P1 — 明显摩擦。任何走过 01-claude-context 流程后再跑 /intake 的项目都会遇到。
这是 "starter 假设需求从0开始" 的隐藏偏见。
