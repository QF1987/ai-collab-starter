---
finding: starter-v3-finding-21
slug: fix-verify-handoff
phase: 06-codex-fix → 04 verify handoff
date: 2026-05-14
severity: P2
---

# Finding 21 — 06-codex-fix 收尾 Next step 跳过 Reporter verify 路径,把 RV 闭合责任直接甩给 Human

## 现象

P1 #2(commit `87ead69` fix RV-20260514-02)收尾时,Codex 自动刷的 state.md:

```
Next step:
- Agent: Human
- Prompt 模板: NONE
- 可粘贴 prompt: 请确认 device-agent 最新提交 87ead69 已包含 RV-20260514-02 测试修复...
```

**没有把 Next step 指向 Reporter (OC) 做最后的 `verified` 翻态**,而是直接跳到 Human merge。

## 与 starter v2.0 workflow.md 关闭规则冲突

`workflow.md > 关闭规则`(同步自 starter v2.0):

> finding 必须由 Reporter(不是 fix 实施人)翻 `verified` 才算关闭。P0/P1 未 verified 不得合并。

P2 没有"未 verified 不得合并"硬约束,但**Reporter verify 才能翻 verified** 的规则仍适用。Codex 跳过这步等于:
- RV 闭合责任甩给 Human(隐式代行 Verifier)
- 没有结构化的 OC 复审一轮
- 工作流闸门 03→04→06→04 的最后一个 04 缺失

## 影响

1. **P0/P1 finding 风险**: 如果是 P0/P1 finding 用同样路径,直接绕过强制 Reporter verify,违反硬约束
2. **状态记录失真**: review.md RV 翻 verified 的依据从"OC 独立复审"降为"Human 看一眼", audit trail 弱
3. **OC 在 fix 后没有反馈通道**: 比如 fix 实施过程中暴露了 Expected fix 描述不完整 / fix 范围有歧义,
   原本可以在 verify 一轮里 catch,现在错失
4. **dogfood 信号丢失**: 完整的 03→04→06→04 闭环没跑过一次,无法收集"v2.0 在 verify 后续轮的开销"信号

## 根因

`.ai/prompts/06-codex-fix.md`(v2.0)收尾段对 Next step 没有强约束:
- workflow.md §5.2 只规定了"escalate to Claude"路径,没规定"fix 后必须回 Reporter verify"
- 03-codex-implement.md 收尾段规定了"必须接 04-opencode-review",但 06-codex-fix.md 缺类似规定
- Codex 自由发挥,选了最短路径(直接给 Human)

## 建议(starter v3.0)

### 修复 A · `06-codex-fix.md` 加强约束(类比 03 的"必须接 04")

```markdown
## 收尾纪律(v3.0 新增 · 强约束)

修复 RV finding 完成后,你产出的 state.md `Next step` 段:

1. **必须**指向 Reporter 做 verify(Agent = 该 RV 的 Reporter 字段值;对 OpenCode/Claude 两种 Reporter
   都适用)
2. Prompt 模板 = `.ai/prompts/04-opencode-review.md`(Reporter=OpenCode) 或描述性 prompt(Reporter=Claude)
3. **禁止**直接把 Next step 指向 Human 跳过 Reporter
4. 例外:仅当 RV severity = P3 且 fix < 10 行 时,可指向 Human(Reporter 显式代行)
5. P0/P1 finding 严禁跳过 Reporter verify,违反即视为 RV 闭合无效
```

### 修复 B · workflow.md §5 / §6 互锁规则

workflow.md §6(Codex fixes only approved findings)加一句:

> Codex 实施 fix 完成后,Next step 必须**先指 Reporter verify**,Reporter 翻 verified 后才走 Human merge。

并把 §5 关闭规则升级:

> P0/P1 finding 跳过 Reporter verify 直接 close 视为"未 verified",违反"合并"门槛。

### 修复 C · state.md 校验注释加一条

```markdown
<!-- 校验规则(v3.0 新增):
  - 若 Last completed.Step 含 "06-codex-fix",则 Next step.Agent 必须是 RV 的 Reporter
    (典型: OpenCode);除非 RV severity = P3 且 < 10 行 fix 时可指 Human
  - P0/P1 finding 直接跳到 Human 视为 state.md 损坏
-->
```

## 严重度

P2 — 当前 P1 #2 case 走运,P2 finding + small fix + 单文件,Human 代行 verify 风险可控。
但**制度缺口客观存在**,任何 P0/P1 fix 用同样路径会直接违反硬约束。建议 v3.0 必修,
和 Finding 13(03→04 闸门)、Finding 14(scope creep)同属"工作流闸门完整化"组。

## 关联

- Finding 13: 03 完成后必须接 04(同性质,缺 06 完成后必须回 Reporter verify)
- Finding 14: Codex 越权决策边界(本 finding 是 14 的延伸 — Codex 自动决策 Next step 路由)
- Finding 20 F-C: state.md prompt 模板化建议(本 finding 给出具体补丁内容)

建议 v3.0 把 13 / 14 / 21 / 20-F-C 合并为一个 "工作流闸门完整化" 主题升级,逐条 patch。
