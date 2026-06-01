---
finding-id: starter-v5.3-finding-33-regression-revert-verify-feature-changes
severity: P3
category: prompt + rubric
source-project: deviceops
discovered: 2026-06-01
target:
  - .ai/prompts/04-review.md (Quality 段 C6 + review checklist)
  - .ai/prompts/03-implement.md (测试纪律)
  - .ai/getting-started.md (Acceptance Criteria 通用段)
status: pending
related: [10, 30]
---

# Finding 33: 「回归测试 revert 后必须 fail」纪律未覆盖 feature/数据语义改动(只在 bug 任务强调 → test-the-mock 假绿)

## 现象

DeviceOps M3-GA 在**非 bug 的 feature/语义改动**里**两次**遇到「单测 PASS 但测的是 mock/fake 不是真代码」:

1. **S2 D5 timestamp sticky**:回归测试跑在 `fakeRateLimitDB` 上,fake 自己实现了 set-once 语义 → 即使 revert `releases.go` 的真实 `COALESCE` 改动,单测**仍绿**(测的是 fake 的行为,不是 SQL)。
2. **M3-GA followup D1 per-peer ledger**:核心机制(保留已断开 peer 的累计)**无直接单测**,因为 `lt::peer_info_alert` 难廉价构造 → 只测了下游纯函数,revert ledger 改动不会 fail。

bug-intake 的 AC 已有「回归测试:复现脚本/单测能在 patch 前 fail、patch 后 pass」(且 lite-finding-10 同主题已在 lite 线消化),但**只 enforce 到 bug 任务**;Medium/Large **feature/数据契约/语义**改动的回归测试没有这条门槛。

## 影响

- 改数据契约/语义的 feature(如 D5 timestamp sticky 这种 L1 语义变更)单测假绿:reviewer 看 PASS 就放过,实际 revert 真改动测试照样过 → 保护价值为零。
- 这类「测 mock 不测代码」在 required-review 的语义改动上尤其危险(正是最需要回归守护的地方)。

## 根因

「revert patch 测试必须 fail」是通用测试有效性纪律,但 starter 只把它下沉到 bug 流程(getting-started bug AC)。feature 流程(03-implement / 04-review quality)没有等价 enforce;reviewer 三步法 quality 段不检「这测试 revert 真改动后会不会 fail」。

## 提议

- `04-review.md` Quality(C6)+ review checklist 加一条,对**改数据契约/语义的 feature 改动**:
  > 回归测试须能在 revert 真实改动后 fail(测代码,不测 mock/fake)。若因 fixture/mock 难造(如外部库 alert、无真 DB)无法满足,**显式标注**「该断言验证 mock/fake 行为,真验证依赖 X(集成/真机/真 DB)」+ 指明真验证承接处 —— **不许默认绿**。
- `03-implement.md` 测试纪律段呼应:写回归测试时自检「我这测试 revert 后会 fail 吗?还是 mock 替我过了?」。
- 与 finding-30(telemetry lifecycle 闭环测试)、lite-finding-10(bug revert-verify)同族,可合并表述为「测试有效性:测代码不测 mock」通用纪律。

## 证据

- DeviceOps `.ai/review.md > Claude Verify: M3-GA S2`(fake-DB sticky 测试「同既有 CompletionPathSticky 基线模式,revert SQL 不 fail 单测」P3 观察)。
- DeviceOps `.ai/review.md > Claude Review: P2P 字节计数 fix`(D1 ledger 无直接单测 P3 · `lt::peer_info_alert` 难 mock · 真验证走 go-live Lima fleet-smoke)。

---
## 实施(v5.4.0-rc1 · 2026-06-01)
- `.ai/prompts/04-review.md` 第三步 Quality:新增「测试有效性:测代码不测 mock」纪律(紧邻 lifecycle 闭环 finding-30),把 bug 任务的「revert 后 fail」AC 扩展到 feature/数据语义改动 + mock 难造时显式标注承接处。
