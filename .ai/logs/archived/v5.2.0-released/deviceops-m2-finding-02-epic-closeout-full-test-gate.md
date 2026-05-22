---
finding-id: deviceops-m2-finding-02-epic-closeout-full-test-gate
severity: P2
category: prompt + workflow
source-project: deviceops
discovered: 2026-05-22
target:
  - .ai/prompts/04-review.md (epic 末切片 review / 收尾段)
  - .ai/workflow.md (epic 收口段)
status: pending
related: [deviceops-m2-finding-01-multi-decision-cross-check]
---

# Finding 02: epic 收口缺「全量复跑测试」强制闸门——非本切片起源的红测试被漏过

## 现象

M2-D（5 切片 Epic）最后一片 S5 的 04-review 由 Scout 执行。Scout 跑 `go test -race ./internal/server/` 时
`TestReportBandwidth` FAIL，Scout 判断「非 S5 引入」→ 标为 observation、不开 finding，给 S5 verdict PASS。

单切片 review 视角下这没错——S5 确实没碰那个测试。但 epic 即将「全收口」，而该包带着一个红测试。
Claude 在 epic 文档收口前做收口预检、复跑全量测试才抓到，升为 **RV-20260522-16（P2）**：
`TestReportBandwidth` 是 M2-C 起源的时间炸弹 fixture（固定 `time.Date` vs handler 的 `time.Now()` 相对窗口），
真实时间过当日某点后必 FAIL。

## 影响

- 单切片 04-review 跑的是「改动相关」测试，非本切片起源的红测试会被合理地判为「非我引入」而放过。
- 但 epic 收口若无「全量测试全绿」强制闸门，就可能在一个包带红测试的状态下宣布 epic / 路线图「全收口」——
  文档说已完成、实际 CI 红，误导后续 session 和 Human。
- 本次靠 Claude 收口预检的自觉补救；缺乏**契约层**的强制要求时，下次未必有人补这一跑。

## 提议 fix

1. `workflow.md` 的 epic 收口段 + `04-review.md` 收尾段增加强约束：
   **epic 最后一个切片 review PASS 后、文档收口前，必须全量复跑测试（`<repo 全量测试命令>`），任何红测试
   ——无论是否本切片/本 epic 起源——都必须在 epic 收口前清零**（开 finding 修复或显式 Human 决策接受）。
2. 单切片 review 看到「非本切片起源的失败测试」时，除标 observation 外，还须**显式登记一条 finding**
   （severity 按测试失败影响定），不能只留观察、让它在 epic 末尾才被发现。

## 实战来源

DeviceOps M2-D S5 dogfood（ai-collab-starter v5.1.0-rc1）。详见 DeviceOps `.ai/review.md` RV-20260522-16、
`.ai/progress.md`「M2-D epic 收口预检」段。

## 实施记录（v5.2.0-rc1 · 2026-05-22）

- `.ai/prompts/04-review.md` 新增「Epic 收口全量测试闸门」段：单切片 review 见非本切片起源失败测试须登
  finding（不只 observation）；epic 末切片 PASS 后、文档收口前必须全量复跑测试，红测试清零方可收口。
- `.ai/workflow.md` §5.4 新增同名段，交叉引用 04-review.md。
- 实施 commit：见 CHANGELOG `[v5.2.0-rc1]` release commit。
