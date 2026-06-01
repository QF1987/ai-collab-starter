---
finding-id: starter-v5.3-finding-32-fail-by-instrumentation-verdict
severity: P2
category: prompt + rubric
source-project: deviceops
discovered: 2026-06-01
target:
  - .ai/prompts/04-review.md (Verdict 段 · 第 4 值 NEEDS-EXECUTION 邻接)
  - .ai/workflow.md (review verdict 轴)
status: pending
related: [28]
---

# Finding 32: review verdict 缺「FAIL-by-instrumentation」档(测试合法失败但根因在 harness/环境而非被测代码)

## 现象

DeviceOps M3-GA S3(本机 Linux VM fleet-smoke)required review:fleet-smoke gate **FAIL**(`peer_positive=0/10`)。但 Claude verify-don't-trust 实读 raw 日志判定:**根因 = 测试 harness/环境(Lima vz loopback self-announce + `from_peers` 周期采样抓不到亚秒级传输)**,被测**产品代码实际 PASS**(原生 Linux 纯-P2P 投递 + 10/10 SHA 正确,无 web-seed)。

四值 verdict `PASS / PATCH / REJECT / NEEDS-EXECUTION` **无一干净对应**:
- 不是 `PASS` —— gate 确实 red。
- 不是 `PATCH` —— 被测产品代码无需改;要改的是测试 harness / 测试环境。
- 不是 `REJECT` —— 无架构/决策错误。
- 不是 `NEEDS-EXECUTION` —— 测试**已实跑**、证据真实(非模板占位符),不是"没跑"。

Claude 当时临时造了个 `FAIL-by-instrumentation` disposition + 交 Human 决策兜过去,但 starter 协议里没有这个档。

## 影响

- E2E / 真机 / 集成 / fleet 类切片天然会遇到"测试失败但根因是环境/采样/harness 不 faithful、被测代码无辜"的情况。没有明确档 → reviewer 要么误判 PASS(掩盖)要么误判 PATCH(让 Impl 白改产品码)要么卡死。
- 这与 NEEDS-EXECUTION(v5.3.0-rc1 finding-28)是姊妹缺口:NEEDS-EXECUTION 管"没跑/模板证据",本档管"跑了且证据真实、但测错了东西"。

## 根因

现有 verdict 轴隐含假设「测试 FAIL ⟹ 被测代码/设计有问题」。对单元/集成内聚测试基本成立,但对依赖真实环境的 E2E/真机/fleet 测试不成立 —— 环境/instrumentation 本身可能是失败源。

## 提议

`04-review.md` Verdict 段(NEEDS-EXECUTION 邻接)补一类判定路径,建议命名 **`FAIL-by-instrumentation`**(或归一到一个明确 disposition):

- **触发**:review 经 **verify-don't-trust 实读** 判定「测试 FAIL 的根因在 harness / 环境 / instrumentation,而被测代码/设计实际工作」。
- **强证据门槛(防滥用)**:必须有实读证据**正向证明被测代码工作**(如 S3 的「无 web-seed 纯 P2P + SHA 10/10 + mesh 真连真实 IP」),否则不许用此档逃避真 bug。
- **下游动作**:不开 code PATCH;① 落 finding(测试/环境侧,owner = 测试 harness/环境)② 交 **Human disposition**(接受 + carry 到有 faithful 环境时复验 / 先修测试再跑 / defer)。
- 与 NEEDS-EXECUTION 区分写清:NEEDS-EXECUTION = 没跑/模板;FAIL-by-instrumentation = 跑了、证据真实、但测错对象。

## 证据

- DeviceOps `.ai/review.md > Claude Review: M3-GA S3 Linux VM bare-metal smoke(2026-05-31)` —— verdict 性质栏明写「不是 PASS/REJECT/NEEDS-EXECUTION」。
- DeviceOps `.ai/review.md > RV-20260531-17`(smoke 假阴性根因)+ `RV-20260601-18`(**同一采样竞态确在生产路径**)—— 证明「instrumentation 判定」不是甩锅,而是精确定位(后续真修了 RV-17/18/19,说明 reviewer 没把真问题当环境问题放过)。

---
## 实施(v5.4.0-rc1 · 2026-06-01)
- `.ai/prompts/04-review.md`:Verdict 表加第 5 值 `FAIL-by-instrumentation`;新增「Verdict 第 5 值」子段(触发 + 强证据门槛防滥用 + 下游 Human disposition + 与 NEEDS-EXECUTION 边界 + M3-GA S3 反例);verdict 路径行(line 38)加第 5 值。
- `.ai/workflow.md`:E2E/真机切片 review 引用补第 5 值。
