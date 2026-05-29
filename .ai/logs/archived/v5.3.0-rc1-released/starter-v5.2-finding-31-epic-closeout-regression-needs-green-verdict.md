---
finding-id: starter-v5.2-finding-31-epic-closeout-regression-needs-green-verdict
severity: P2
category: prompt(04-review Epic 收口闸门)+ workflow(§5.4 全量测试闸门)
source-project: DeviceOps
discovered: 2026-05-29
target:
  - .ai/prompts/04-review.md(Epic 收口全量测试闸门:AC 含「X 回归/E2E PASS」时必须有该 X 的绿 verdict,不可用分场景 PASS 拼凑替代)
  - .ai/workflow.md(§5.4 Epic 收口闸门同步补一句)
status: pending
related: [deviceops-m2-finding-02]
---

# Finding 31: Epic 收口 AC 含「回归/全场景 PASS」时,必须有该脚本的绿 verdict,不能用分场景 split evidence 替代

## 现象

DeviceOps M3-Beta-Scale S5(epic 终点切片)closeout:

- task Phase 5 通过标准 + AC#3 明文写:「`m3-beta-e2e.sh --scenario=all` 全场景 PASS **+ Alpha 回归 PASS**」。
- Impl 实际产出 **split evidence**:proto / 4G / config / install-recovery 各自一个 targeted run 拿到 PASS,拼起来声称 Phase 5 closeout PASS/PATCH,请求翻 6 个 carry-in finding verified + epic CLOSED。
- Claude required review 独立核对发现:**Alpha 回归从未产出 PASS verdict** —— 所有 targeted run `Regression | SKIP`(23 处全 SKIP),唯一 `--scenario=all` 的 regression 在 600s wait 后 `evidence incomplete`。而 RV-20260526-05 的 fix 本体就是「让 Alpha 回归脚本跑通」,其 verified 依赖的正是这个从未出现的绿 verdict。
- 若 review 接受 split evidence 直接 CLOSED,**一个明文 AC(Alpha 回归 PASS)会被分场景 PASS 悄悄绕过**,epic 带着未验证的回归项收口。

关键:split evidence 对「彼此独立的能力维度」(proto / 4G / config)是合理的 —— 但当 AC 点名某个**聚合脚本/回归 suite 的绿 verdict**时,分场景 PASS 不能替代它,因为聚合脚本验的恰恰是「跑通到底 + 不互相干扰 + 脚本自身自动化闭合」这层,而这层往往正是被 carry-in finding(本例 RV-05 = 脚本 wait window/headless)修复的对象。

## 与既有约束的关系

- `deviceops-m2-finding-02`(v5.2.0 · Epic 收口全量测试闸门)已要求「epic 收口必须全量复跑测试,任何红测试清零」。本 finding 是其**精确化补丁**:不仅「不能有红」,而且「AC 点名的回归/全场景 verdict 必须真实存在且为绿,不能用分场景 PASS 拼图替代『从未跑出绿』的那个 verdict」。
- 区别于普通 split:本约束只在「AC 明文要求某聚合脚本/回归 suite PASS」时触发,不波及合理的分维度 ground-truth。

## 提议

1. **04-review.md** Epic 收口全量测试闸门段加:
   > **AC 点名的回归/全场景 verdict 不可被 split evidence 替代**:若 task AC 明文要求「`<script> --scenario=all` PASS」或「X 回归 PASS」,closeout 必须有该脚本/回归**本身的绿 verdict 证据文件**。分场景 targeted PASS 可作为补充,但**不能替代**那个聚合 verdict —— 尤其当某 carry-in finding 修复的正是该脚本的自动化闭合能力时(分场景跑天然绕开被修的那条路径)。无绿 verdict → 该 finding 不得 verified,epic 不得 CLOSED;给出「最小补跑 gate」而非接受拼图。
2. **workflow.md §5.4** 末尾补一句指针,引到上方。
3. 反例锚点:DeviceOps M3-Beta-Scale S5,Alpha 回归 23 run 全 SKIP + 1 run incomplete,split evidence 一度差点替代「Alpha 回归 PASS」AC;Claude review 拦下,指定最小 gate = leecher-healthy 真机单跑 `m3-alpha-e2e.sh` 出绿。

## 适用范围

所有有「聚合 E2E / 回归 suite + 分场景子命令」结构的项目(本例 shell E2E;等价于 `pytest -k`、`mvn verify` 全量 vs 单测、Cypress full-run vs single-spec)。

## 来源

- DeviceOps M3-Beta-Scale S5 Phase 5 closeout(2026-05-29)· Claude required review 判 PATCH(非接受 split-as-closeout)。
- 反向 dogfood:Impl split evidence 请求 epic CLOSED,但 AC 点名的 Alpha 回归绿 verdict 不存在;若无此约束,review 容易被「四项都 PASS 了」说服而放过未验证的第五项。

---

## 实施记录(v5.3.0-rc1 · 2026-05-29)

- `.ai/prompts/04-review.md`:Epic 收口全量测试闸门段加第 3 条「AC 点名回归/全场景 verdict 不可被 split evidence 替代」+ 反例(M3-Beta-Scale S5 Alpha 回归)。
- `.ai/workflow.md` §5.4:补同条指针。
- 与 deviceops-m2-finding-02 关系:本条是其精确化补丁(不仅不能有红,AC 点名的聚合 verdict 必须真实为绿)。
- 关联 commit:见 CHANGELOG v5.3.0-rc1。
