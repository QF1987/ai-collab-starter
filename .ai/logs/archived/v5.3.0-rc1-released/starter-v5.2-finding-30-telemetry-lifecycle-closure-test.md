---
finding-id: starter-v5.2-finding-30-telemetry-lifecycle-closure-test
severity: P3
category: prompt(03-implement 测试纪律 + 04-review 检查清单)
source-project: DeviceOps
discovered: 2026-05-27
target:
  - .ai/prompts/03-implement.md(实施期「状态/telemetry 字段闭环测试必须覆盖完整 lifecycle」自检)
  - .ai/prompts/04-review.md(三步法 Quality 子项加「lifecycle 闭环」检查)
status: pending
related: [27]
---

# Finding 30: telemetry / 状态字段闭环测试必须覆盖完整 lifecycle 上报序列

## 现象

DeviceOps M3-Beta-Scale S3(telemetry `completion_path` 跨仓字段)实施中:

- Impl 给设备状态上报新增 `completion_path` enum(P2P_PRIMARY / WEB_SEED_PRIMARY / HTTP_FALLBACK_*),device 端仅在 `downloaded` 状态上报真实 path,其它状态(downloading / installing / installed)保持 UNSPECIFIED。
- Impl 的 telemetry 实采测试**只跑了单次 `downloaded` 上报**,查 DB 得 `P2P_PRIMARY | 1`,判 PASS。
- Claude 04-review 复盘完整 lifecycle 才发现:server 端 `UpdateReleaseBatchDevice` 用 unconditional `completion_path = $6`,后续 `installing`/`installed` 上报 UNSPECIFIED → SQL NULL → **把已写入的 `P2P_PRIMARY` 清空**。
- 结果:跑完整 lifecycle 后 dashboard 所有「已安装」设备都显示 legacy/NULL,**telemetry 字段的核心价值(运维区分 P2P vs HTTP fallback 完成率)实际丢失**(P1 · DeviceOps RV-20260526-11)。

也就是说:Impl 测「首次写入正确」,漏测「后续状态不会覆盖」。单点写入 PASS ≠ lifecycle 闭环 PASS。

## 根因

状态机类字段(status / completion_path / 各种 *_at 时间戳)的正确性是**跨多次上报的累积语义**,不是单次写入语义。但常见测试惯性是「构造一次上报 → 查值 → 判 PASS」,天然只覆盖 lifecycle 的第一跳。后续状态对同字段的 sticky / overwrite 行为是隐藏决策空间,单点测试照不到。

附带:同一 `UpdateReleaseBatchDevice` 对时间戳列(ready_at/downloading_at/...)也是 unconditional overwrite,历史已存在但 dashboard 没显示这些列所以一直没暴露 —— 进一步印证「单点写入测试」会系统性放过这类 bug。

## 提议

1. **03-implement.md** 加实施期自检(状态/telemetry 字段类改动触发):
   > 新增/修改「跨多次上报累积」的状态字段(status / 完成路径 / 阶段时间戳 / 计数器)时,测试**必须**覆盖**完整 lifecycle 上报序列**(典型:pending → downloading → downloaded → installing → installed),断言**终态字段值符合预期**(不被中间态覆盖 / 不被清空)。单次写入查值 PASS 不算闭环。
2. **04-review.md** 三步法 Quality 子项加一行(所有语言通用):
   > **lifecycle 闭环**:状态字段类改动,确认测试跑了完整上报序列;server 端 UPDATE 语句对「本次不带值」的字段是 overwrite 还是 sticky(COALESCE/NULLIF),与 device 端「仅某状态上报」语义是否一致。
3. 反例锚点:DeviceOps RV-20260526-11(`completion_path` 被后续 UNSPECIFIED 上报清空),修复用 SQL `COALESCE(NULLIF($6, ''), col)` + 4 步 lifecycle 单测。

## 适用范围

任何语言/框架 —— 凡有「客户端分阶段上报 + 服务端 upsert 同一行」模式(IoT 设备状态、订单状态机、任务进度上报、CI pipeline stage)都撞同一陷阱。

## 来源

- DeviceOps M3-Beta-Scale S3 telemetry(2026-05-27)· Claude 04-review 抓出 RV-20260526-11(P1)。
- 反向 dogfood:Impl 测试停在「首次 downloaded 上报」,Claude review 跑完整 lifecycle 才发现 overwrite。

---

## 实施记录(v5.3.0-rc1 · 2026-05-29)

- `.ai/prompts/03-implement.md`:新增「状态/telemetry 字段闭环测试纪律」段(完整 lifecycle 序列 + 终态断言 + 服务端 overwrite vs sticky 核对)。
- `.ai/prompts/04-review.md`:第三步 Quality 通用项加「lifecycle 闭环」检查行。
- 关联 commit:见 CHANGELOG v5.3.0-rc1。
