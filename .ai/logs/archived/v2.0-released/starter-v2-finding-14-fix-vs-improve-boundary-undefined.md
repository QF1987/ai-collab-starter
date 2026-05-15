---
finding: starter-v2-finding-14
slug: fix-vs-improve-boundary-undefined
phase: 06-codex-fix → 04-opencode-review handoff
date: 2026-05-13
severity: P2
---

# Finding 14 — 06-fix / 04-review 边界:Codex 顺手 refactor 是否合法 + OC 是否需要 return to Claude,starter 无明文规定

## 现象

E1 Slice 1 RV-01..04 fix → review 闭环中出现以下情况:

**Codex 端**(06-codex-fix):
- RV-04 期望 fix 是"删除一行 `postgres.start();`"(明确写明 1 行修改)
- Codex 实际产出:
  - `AbstractIntegrationTest.java -21 行`(删除整个 `@Container` 字段 + `@DynamicPropertySource` 方法)
  - `application-test.yml +5/-1 行`(改用 `jdbc:tc:postgresql:15-alpine:///` Testcontainers JDBC URL 模式)
- 等于**测试基础设施模式从 `@Container` 重构为 JDBC URL prefix 模式**——这是架构改动,
  不是 RV-04 描述的简单修复

**OC 端**(04-opencode-review):
- OC 读 diff,识别了 scope 超出,显式记录"比原修复建议更干净"
- OC 做出 **自行接受 + verified** 的判断
- OC **没有** 按 workflow.md §6 "New architecture issues return to Claude" 的规则升级

## 根因

starter 当前 `.ai/prompts/06-codex-fix.md` 和 `.ai/prompts/04-opencode-review.md` 对以下边界
**没有任何明文规定**:

1. **Codex 在 fix 中能不能做 fix 范围之外的"顺手改进"?**
   - 严格解读 workflow.md §6"Codex fixes only approved findings":不能
   - 宽松解读:小范围 idiomatic 改进算"fix 的最佳实现",可以
   - 当前 06 prompt 没明确选哪种解读

2. **OC 在 review 中遇到 Codex 顺手 refactor,该如何处理?**
   - workflow.md §6 写"New architecture issues return to Claude"
   - 但 04 prompt 没有把这条规则操作化(没说"如何识别 architecture 改动"+ "升级到 Claude 的具体动作")
   - OC 实际行为:自行判断 + 接受;没升级

3. **何为"architecture change"?**
   - 测试基础设施的模式切换(`@Container` ↔ JDBC URL)算不算 architecture?
   - 这个边界判定模糊,且每个 Agent / 每个项目可能不一样

## 影响

- **静默扩大 fix 范围**:Codex 可以借 fix 之名做 refactor,OC 凭"看着更干净"放行,
  这条路径在金融/医疗等高合规项目里是不可接受的(每个改动需 paper trail)
- **架构决策绕过 Claude**:本次测试基础设施重构是 Codex + OC 二人决定的,Claude(架构层 owner)未被通知
- **不同项目/不同 Agent 行为不一致**:同一份 starter,有的项目可能严格执行"删 1 行",
  有的允许 refactor,造成跨项目协同混乱
- **本次 case 结果其实 OK**:OC 显式知情接受,代码确实更 idiomatic,无功能回退;
  但**幸运不是制度**

## 影响等级判定

**P2** —— 当前事件无功能损害,但暴露了制度边界缺口;在风险敏感项目里同样模式可造成 P0 后果。

## 建议(starter v2.0)

### 修复 A · `06-codex-fix.md` 增加 scope 强约束段

```markdown
## Scope 强约束

你只允许改 RV finding 明确列出的"Expected fix"段中描述的代码位置。
若实施过程中发现可以"顺手做"的相邻改进(如重构周边代码、采用更 idiomatic 写法),
**必须停下,不要实施**,转而:

1. 在 review.md 该 RV 下追加 "Implementer note(stop and ask)" 段,
   描述发现的改进机会
2. state.md Next step 设为 "Claude 决策是否接受顺手改进"(不要直接接 04 review)
3. 提交一次"半成品"commit,等 Claude 决策后再继续

例外:若改进 ≤ 3 行 且 是 Expected fix 自然延伸(如 import 清理 / typo 修正),
可直接做,但需在 commit message 注明"顺带改进:XXX"。
```

### 修复 B · `04-opencode-review.md` 增加"scope creep 升级"分支

```markdown
## Scope 验证(必做)

review 时第一步:对照 review.md 中各 RV 的 Expected fix,核对 Codex 实际 diff:

1. 若 diff 严格在 Expected fix 范围内 → 正常 verify 流程
2. 若 diff **超出 Expected fix 范围**(行数 / 文件数 / 修改类型),
   **必须**:
   - 在 review.md 该 RV 状态字段写明 "scope-deviation detected: ..."
   - **状态不要直接翻 verified**,翻 `escalated`
   - state.md Next step 设为 "Claude · 05-claude-review · scope deviation 决策"
   - 由 Claude 决定:接受 → verified;不接受 → 新增 RV 要求 Codex 回滚

scope-deviation 的判定标准:
- 修改文件数超过 Expected fix 字面描述的 1.5 倍
- 单文件 diff 行数超过 Expected fix 描述行数的 2 倍
- 改变了已有 annotation / 类继承 / 配置文件结构
- 满足任一即触发升级
```

### 修复 C · workflow.md §6 补"architecture change"定义清单

把"new architecture issues"操作化为可机器识别的判定清单(参考修复 B 中的判定标准),
并把"return to Claude"的具体动作写明(state.md Next step 字段、新增 RV 还是注明 escalated)。

## 严重度

P2 — 当前 case 走运不出事,但**制度缺口客观存在**,在风险敏感项目里同样模式可造成
P0 静默架构改动。建议 v2.0 必修,与 Finding 13(工作流闸门)同属"流程纪律强化"组。

## 关联

- Finding 13(工作流闸门未强制):本 finding 是 13 的延伸——13 关注"是否走 review",
  本 14 关注"走 review 时如何识别 scope creep + 升级路径"
- review.md RV-04 是本 finding 的真实案例,可作为 v2.0 文档化的反面教材
