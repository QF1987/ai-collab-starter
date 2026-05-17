---
finding-id: lite-v0.1-finding-08-oc-review-b7-state-completeness
severity: P3
category: prompt
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/prompts/04-opencode-review.md (3b · Codex 自审盲点专项 checklist)
status: pending
related: [02]
---

# Finding 08: OC-review 04 自审盲点 checklist 漏 "state.md 字段完整性" B7

## 现象
lite 04-opencode-review.md > 3b · Codex 自审盲点专项 checklist B1-B6 涵盖:
- B1 子任务包颗粒度
- B2 Codex 03c 给具体证据
- B3 OC-impl 100% 覆盖必做
- B4 pre-decisions 翻案检测
- B5 推倒重来检测
- B6 human-override 检测

但没列**"state.md 字段完整性"** 这条。本次 smart-uite Step 2 Codex 02 跑完后, state.md 多字段被 condensed (finding 02 详述), OC-review 跑三步法时也无 checklist 项捕获这个。

## 影响
- state.md 漂移成为 lite 系统级风险, OC-review 没兜底, 多轮累积后 state.md 退化
- finding 02 修了 prompt 收尾段硬约束, 但若 Codex 仍漏, OC-review 应该 catch — 现在没 catch

## 根因
04-opencode-review.md > 3b 写 6 条 (B1-B6), 没考虑 state.md 跨 Agent 流转, 而 lite Pattern A 强依赖 state.md 准确性。

## 证据
- 本对话 Step 2 后我手动 catch state.md 字段缺失, OC-review 本应能机器化检测但没工具
- finding 02 是 prompt 收尾段强约束, finding 08 是 review 兜底

## 提议修复
**`04-opencode-review.md > 3b · Codex 自审盲点专项 checklist`** 末尾加 B7:

```markdown
- [ ] **B7**. state.md 字段完整性: 当前 state.md 是否按 lite template 完整保留所有字段名 + 维护规则段 + Pattern A/B 段
  - 验证方法 (机器化):
    ```bash
    # 字段名应存在
    grep -c '当前阶段\|Last completed step.Agent\|Last completed step.Step\|Last completed step.产出\|Next step.Prompt 模板\|Next step.触发来源\|Next step.触发条件\|Next step.输入' .ai/state.md
    # 应 ≥ 8 (8 个核心字段名)

    # 维护规则段应存在
    grep -c '## 维护规则\|## Human vs Agent\|### Pattern B 的安全栏' .ai/state.md
    # 应 = 3
    ```
  - 命中信号: 字段名漂移 (e.g. "Next step.输入" 被改成 "关键输入") / 头部标题被简化 / 维护规则段被删
  - 严重度: P2 (lite 系统级风险, 但不直接阻塞当前 bug)
```

## SemVer 影响
**PATCH** (纯 checklist 新增, 不改 prompt 主体契约)。
