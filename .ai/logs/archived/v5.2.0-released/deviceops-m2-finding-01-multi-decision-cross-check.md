---
finding-id: deviceops-m2-finding-01-multi-decision-cross-check
severity: P2
category: prompt
source-project: deviceops
discovered: 2026-05-22
target:
  - .ai/prompts/02-claude-plan.md (决策段 / 各段强约束)
status: pending
related: []
---

# Finding 01: 02-claude-plan 缺「多决策交叉检查」——多个 Decision 写同一状态/资源时意图冲突未被发现

## 现象

M2-D（运维面板 + 熔断/降速）epic 的 ADR-20260522-03 含 7 条 Decision。其中：

- **D2**（限速值热加载）：`MetricsSampler` 每 5s 读 `rate_limit_config`，若变化则 `limiter.SetBPS(cfg.BPSLimit)`。
- **D6**（自动降速）：熔断 `evaluateBandwidth` 过载时 `limiter.SetBPS(cfg.BPSLimit × throttleRatio)`。

两条 Decision **都写同一个资源 `limiter` 的 BPS**，但意图相反（D2 要把 limiter 拉回 config 值，D6 要把它压到 config 值以下）。
plan 阶段没有检查到这个冲突。Impl 忠实实现后，S3 review 暴露 **P1 缺陷（RV-20260522-12）**：自动降速每被 D2 热加载在
下一个 5s tick 撤销，自动降速实际不生效、振荡。根因是 ADR 内两个决策未协调——既不是 Impl 的错，也不是单个 Decision 的错，
而是 plan 阶段缺「决策之间是否打架」的交叉检查。

## 影响

ADR 决策数越多，跨决策资源冲突越难靠人眼发现。02-claude-plan 当前各段强约束（Compatibility L1-L5、Paths 分两组、
Consequences 双段等）都是**单决策维度**的，没有一条要求审视「决策 × 决策」的交互。架构级缺陷漏到实施后才由 review 第二步抓到，
成本高于 plan 阶段拦截。

## 提议 fix

`02-claude-plan.md` 增加一条强约束「多决策交叉检查」：

- 出 ADR 含 ≥ 2 条 Decision 时，必须列一个「决策交互检查」自检：哪些 Decision 写/改**同一状态、资源、配置项、表列**？
- 对每一组「多 Decision 触碰同一目标」，必须在 ADR 显式声明**谁主导 / 写入顺序 / 冲突时以谁为准**，
  或确认彼此正交（不同字段/不同时机）。
- 反例固化：D2 热加载 vs D6 自动降速都写 `limiter` BPS，未声明主导方 → P1。

## 实战来源

DeviceOps M2-D S3 dogfood（ai-collab-starter v5.1.0-rc1）。详见 DeviceOps `.ai/review.md` RV-20260522-12、
`.ai/decisions.md` ADR-20260522-03 的「Amendment 2026-05-22（D2/D6 协调）」段。

## 实施记录（v5.2.0-rc1 · 2026-05-22）

- `.ai/prompts/02-claude-plan.md` 新增「多决策交叉检查」强约束段（置于「决策必须落到唯一具体选择」与
  「Alternatives 必须覆盖 UX/行为等价维度」之间）：ADR ≥ 2 Decision 时必须做决策×决策交叉检查，
  对多 Decision 触碰同一资源（状态/配置/limiter/单例等）显式声明主导方或论证正交。
- 实施 commit：见 CHANGELOG `[v5.2.0-rc1]` release commit。
