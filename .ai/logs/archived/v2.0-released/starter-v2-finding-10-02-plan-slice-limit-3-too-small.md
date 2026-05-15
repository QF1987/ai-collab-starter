---
finding: 10
slug: 02-plan-slice-limit-3-too-small
phase: 02-claude-plan
date: 2026-05-13
severity: medium
---

# Finding 10: `02-claude-plan` 硬限「≤ 3 切片」对多层 Java/Spring Boot Epic 不适用

## 现象

`02-claude-plan.md` 提示词写道：

> "把实施切成有边界的 Codex 任务（≤ 3 切片，每片一个 PR）"

PaymentRecon E1 自然分解为 4 个 Slice：

- Slice 1：DB 层（DDL + 实体 + Mapper）
- Slice 2：渠道适配层（CSV 解析 + SPI）
- Slice 3：引擎层（轧差算法 + 状态机）
- Slice 4：API 层（REST + DisputeService）

## 根因

「≤ 3 切片」的隐含假设：典型 starter 场景是 **Web 全栈 Epic**——
`前端 Slice + 后端 Slice + DB/协议 Slice`，3 片足够。

批处理型 Java Epic 有更深的层次栈（DB / Adapter / Engine / API），
每层内聚性高、层间接口清晰，强行压到 3 片会：
- 把 DB 层和 Adapter 层塞进 Slice 1（一个 PR 改动 40+ 文件）
- 或把 Engine 层和 API 层合并（高风险逻辑与低风险路由混在一个 PR）

两种压法都降低了 PR review 质量和 Codex 单次任务的可控性。

## 建议修复（starter v2.0）

`02-claude-plan.md` 改为：

> "把实施切成有边界的 Codex 任务（**推荐 3-5 切片**，每片一个 PR）。
> Web 全栈 Epic 通常 3 片；批处理 / 多层后端 Epic 可到 4-5 片。
> 单片 PR diff 应控制在 300-500 行内，超过则继续细切。"

## 影响

- 本次 E1 实际切 4 片，违反 `≤ 3` 字面约束
- 不违反 `≤ 1 PR per Slice` 原则（每片依然单 PR）
- starter v2.0 升级后此 finding 关闭
