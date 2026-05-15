---
finding: starter-v2-finding-13
slug: workflow-review-gate-not-enforced
phase: 03-codex-implement → 04-opencode-review handoff
date: 2026-05-13
severity: P1
---

# Finding 13 — 工作流 04/05 review 关卡未被强制,Codex 可直接把 Next step 指向下一个 Slice

## 现象

E1 Slice 1 实现完成后,`.ai/state.md` 的 Last/Next 段直接写:

- Last completed step: `Codex · 03-codex-implement` (Slice 1)
- Next step: `Codex · 03-codex-implement` (Slice 2)

**完全跳过了** workflow.md §5 规定的:
- `04-opencode-review`(OC 低成本审视)
- `05-claude-review`(架构敏感时 Claude 复审)

`.ai/review.md` 跑完 Slice 1 后仍是空白模板。

## 根因

`.ai/prompts/03-codex-implement.md` 的「下一步提示词」段落对 Slice 完成后的下一步缺少强制约束。
当前 Codex 自行判断"既然 mvn test 绿,直接进 Slice 2 即可",而 prompt 模板没有写明:

> 03 完成后下一步 **必须** 是 04-opencode-review,不允许直接跳到下一个 Slice 的 03。

state.md 的 Next step 字段也没有「上一步是 03 必须接 04」的格式校验。

## 影响

- **review.md 静默为空**:工作流 §5 描述的关卡形同虚设;Slice 1 的代码 0 人审过就成为 Slice 2/3/4 的基础
- **错误会向下传播**:Slice 1 的 schema/entity 即使有问题(如 `DisputePool.status` 类型不一致),
  Slice 2/3 实现时直接基于错误代码继续,等到 Slice 4 集成测试才暴露 → 修复成本翻倍
- **starter 的"多 Agent 协同"价值打折**:如果 Codex 既写又决定下一步,等于回到「单 Agent 干完一切」的模式,
  Claude/OpenCode 的角色被绕过
- **隐性鼓励 Codex 越权**:Codex 在 03 完成时本应只汇报"我做完了,下一步应该是 OC review",
  现在它直接产出"下一步是 Slice 2 的可粘贴 prompt",已经越权代行 Claude 的调度职责

## 建议(starter v2.0)

### 修复 A · 03-codex-implement.md 强制下一步模板

在 `.ai/prompts/03-codex-implement.md` 的「收尾纪律」段加入硬性规则:

```markdown
## 收尾纪律(强约束)

完成 implement 后,你产出的 state.md `Next step` 段:

1. **必须**指向 `04-opencode-review` 这一步,Agent 必须填 `OpenCode`,
   prompt 模板必须填 `.ai/prompts/04-opencode-review.md`
2. **禁止**直接跳到下一个 Slice 的 03;即使你自测全绿,也必须经 review 关卡
3. **禁止**自己产出"下一个 Slice 的可粘贴 prompt"——那是 04 review 通过后 Claude 决定的
4. 例外:仅当本 Slice 是单文件 < 30 行的小补丁(由 Claude 在 task 文件中显式标 `skip-review: true`)时,
   方可直接进下一步;此时 state.md Next step 需注明"已豁免 review,豁免理由 X"
```

### 修复 B · state.md 模板加格式校验注释

在 `.ai/state.md.template` 的 `Next step` 段附近加注释:

```markdown
<!-- 校验规则:
  - 若 Last completed.Step 包含 "03-codex-implement",则 Next step.Agent 必须是 OpenCode
    且 Prompt 模板必须是 04-opencode-review.md
  - 违反此规则的 state.md 视为损坏,需 Claude 复检后才能继续
-->
```

### 修复 C · workflow.md §5 增加强制语句

workflow.md §5 当前写"OpenCode performs low-cost review first",改为:

> **每个 03-codex-implement 步骤完成后,04-opencode-review 是不可跳过的必经步骤,
> 除非 Claude 在 task 文件中显式标 `skip-review: true`。**

## 严重度

P1 — 明显摩擦,且**静默放过质量门**。本次 E1 已经因此漏审 Slice 1,
若不补救,后续 Slice 都会基于未审过的代码继续。
建议 v2.0 必修,优先级与 Finding 04(Epic 模板)同级。
