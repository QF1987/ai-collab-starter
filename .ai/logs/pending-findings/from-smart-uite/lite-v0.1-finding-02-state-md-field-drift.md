---
finding-id: lite-v0.1-finding-02-state-md-field-drift
severity: P2
category: prompt + rubric
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/prompts/02-codex-plan.md (收尾段)
  - .ai/prompts/03-codex-orchestrate.md (收尾段)
  - .ai/prompts/04-opencode-review.md (Codex 自审盲点专项 B 项)
  - .ai/prompts/oc-helper.md (Notes 段)
  - .ai/state.md (template 顶部加 "字段完整性硬约束"段)
status: pending
related: [08]
---

# Finding 02: state.md 字段被 Codex 简化漂移, 缺关键 invariant

## 现象
Codex 02 跑完 L2 摸排后自己刷 state.md, **template 定义的多个字段被 condensed 掉**:
- `Active task.当前阶段` 没填
- `Last completed step.Agent` 没显式标 (语境推断是 Codex)
- `Last completed step.Step` 没显式标
- `Last completed step.产出` 没填
- `Next step.Prompt 模板` 没填
- `Next step.触发来源(lite)` 没填
- `Next step.触发条件` 没填
- `Next step.输入` 字段名变成 "关键输入" (字段名漂移)

state.md 头部从 `# Session State (lite v0.1.0)` 简化成 `# State`, 删除了维护规则段 + Pattern A/B 安全栏段。

## 影响
- state.md 失去 self-contained 特性, 跨 session 重建上下文质量下降
- 检查规则(template 注释中的 v0.1.0 触发源校验)被删除后, 后续 Agent 不知道该按哪些规则填字段
- 多次刷漂移会越来越简化, 最终退化为"自由格式 markdown"违背 lite 设计

## 根因
- `02-codex-plan.md` 收尾段只说 "覆盖写入 state.md", 没说 "**必须保留 template 所有字段, 不能 condensed**"
- `03-codex-orchestrate.md` 同
- `04-opencode-review.md > 3b · Codex 自审盲点专项` B1-B6 没列 "state.md 字段完整性"
- state.md template 顶部注释段没有"字段必须按本 template 完整保留"硬约束

## 证据
- 本对话 2026-05-17 22:52 系统提醒显示 Codex 写的 state.md 仅 46 行, lite template 完整版 105 行
- 我事后手动重写 state.md 补回所有字段 (commit 时间 2026-05-17 23:xx)
- 漂移字段清单见现象段

## 提议修复
1. **`02-codex-plan.md` / `03-codex-orchestrate.md` 收尾段**统一加硬约束:
   ```
   ### state.md 覆盖前必读 (硬约束)
   覆盖写入 state.md 前必须先 Read 当前文件 + 复制完整 template 结构。
   禁止: condensed 字段 / 重命名字段 / 删除 template 顶部说明段 / 删除维护规则段 / 删除 Pattern A/B 段。
   只覆盖动态字段值, template 标题 / 注释 / 字段名称 / 校验规则段全部保留原文。
   ```
2. **`04-opencode-review.md > 3b · Codex 自审盲点专项` 加 B7**:
   ```
   B7. state.md 字段完整性: 跑 wc -l .ai/state.md vs lite template (105 行 ± 5), 偏差大 → 字段被 condensed, 升 Human
       验证方法: diff state.md template 检查 template 校验规则注释段是否在
       命中信号: 字段名漂移 (e.g. "Next step.输入" 被改成 "关键输入") / 头部 # 标题被简化
   ```
3. **`oc-helper.md` Notes 段加一行**: "**不**刷 state.md (Codex 03c 的活), 也**不**读 state.md (Pattern A)"
4. **state.md template 顶部 5 行注释段加新条目**: "字段完整性: 后续 Agent 刷本文件时, 必须保留本 template 的所有字段名 + 维护规则段 + 入会话检查段; 字段值可改, 字段结构不能漂移。"

## SemVer 影响
**MINOR** (新增 rubric 维度 B7 + prompt 硬约束)。
