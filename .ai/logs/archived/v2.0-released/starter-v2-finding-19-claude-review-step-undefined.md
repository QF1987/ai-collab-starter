---
finding: starter-v2-finding-19
slug: claude-review-step-undefined
phase: E1 全过程观察
date: 2026-05-14
severity: P2
---

# Finding 19 — 05-claude-review 在实际工作流中从未被显式调用,职责与 04 边界模糊

## 现象

`.ai/prompts/05-claude-review.md` 在 starter v1.0 中定义为独立步骤,workflow.md §5 描述
"Claude reviews architecture-sensitive or high-risk changes",但 E1 全过程(4 个 Slice + 3 轮 fix + 2 轮 verify)
**从未** 作为独立 prompt 被调用。

实际发生的"Claude review"全部以 Chat session 内联方式发生:
- Slice 1 review:Claude(我)替代 OC 做了一次首轮审视(RV-01..04 全由 Claude 提出)
- Slice 2/3/4 review:OC 做 04,Claude 在 Chat 内"我观察到 X,但不剧透给 OC"的旁白
- epic-closeout 决策:Claude 在 Chat 内分桶 / 写 RV / 决定方案,从未单独跑 05

**没有任何一次** state.md `Next step` 写过 "Claude · 05-claude-review · ..."。

## 影响

1. **状态机不完整**:8-prompt 框架的 03→04→(05?)→06 流程实际只有 03→04→06,
   05 是 dead step。starter v1.0 文档说有 8 个 prompt,实际可激活的只有 7 个。

2. **架构敏感判定无明文规则**:workflow.md 说 05 在"high-risk"时触发,但何为 high-risk
   完全靠 OC 主观判断。Slice 4 OC review 看到 AlipayChannelAdapter 加 @Autowired 时
   就遇到这个判定问题——这算"architecture-sensitive"吗?当时 OC 自行接受了,但按文意
   应该 escalate 给 Claude(05)。

3. **Claude 角色双重身份**:Claude 既是"main session 协作者",又名义上是"05 step 执行者"。
   两者职责不分,导致 Claude 在 Chat 内做的 review 没有显式的"我在跑 05"标签,
   review 输出散落在 Chat 历史里而非 review.md 的某段。

4. **可重现性受损**:E1 复盘时,无法说"05 step 在 commit X 产出了 Y"——因为 05 从未单独跑过。
   这破坏 progress.md 的可追溯性。

## 根因

workflow.md §5 的 "Claude reviews architecture-sensitive or high-risk changes" 这一句:
- 没定义 high-risk 判定标准
- 没说由谁触发 05(OC? Human? Claude 自己?)
- 没说 05 的产出落到哪个文件(review.md 同一节?新增 .ai/claude-reviews/?)

prompt `05-claude-review.md` 本身定义了输出格式,但没规定触发条件。

## 建议(starter v2.0)

提供两个互斥方案,选其一:

### 方案 A:把 05 升级为"显式触发 + 文档化产出"

1. workflow.md §5 增加 "Claude review triggers" 子段,列具体触发条件:
   ```
   - 跨 slice 改动(epic-closeout 阶段)
   - ADR 偏离当前 commit
   - OC 04 review 检测到 scope-deviation
   - Human 显式标 high-risk
   ```
2. 触发后 state.md Next step **必须**写 "Claude · 05-claude-review · ..."
3. Claude 在跑 05 时,产出落到 review.md 新段(标 "Claude review · YYYY-MM-DD")
4. 05 完成才能转 06-codex-fix 或 Next slice;不允许"内联跑了但没记录"

### 方案 B:合并 04 和 05

1. 取消 05-claude-review.md 这个独立 prompt
2. 把"architecture 对齐 + scope-deviation 升级"完全交给 04(OC)负责
3. Claude 不再是 review step 的 owner,只在"OC escalate"或"Human 主动求助"时介入
4. workflow.md §5 改写为单 reviewer (OC) 模式 + escalation 路径

**我倾向方案 B**——简化是 starter 的核心价值;方案 A 把工作流变成 5 角色,
增加协调成本。E1 实际运行已经验证 OC 单一 reviewer + Claude 协作者模式可行
(13 条 RV 全部闭合,无静默漏过的架构问题)。

## 严重度

P2 — 不阻塞任何流程,但**8-prompt 框架的 1/8 是 dead code**,
starter v2.0 必须给说法(实施方案 A or B),否则文档名实不符。
