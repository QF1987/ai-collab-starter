---
finding: 11
slug: two-group-paths-insufficient-java-layers
phase: 02-claude-plan
date: 2026-05-13
severity: low
---

# Finding 11: 「核心改动 paths + 连带改动 paths」二分对 Java 多层结构信号不足

## 现象

`02-claude-plan.md` 要求每个 Slice 的 paths 按两组列出：

- **核心改动 paths**：业务逻辑直接改动的文件
- **连带改动 paths**：interface mock / schema 同步 / 生成代码 / 测试文件等

在 Go/Node 项目中，一个功能通常改动 2-5 个文件，二分清晰够用。

在 Java Spring Boot 项目中，Slice 3（ReconEngine）的核心改动就有：
`ReconEngine.java` + `ReconTaskService.java` + 4 个 XML Mapper 文件 = **6 个核心文件**。
连带改动是 4 个 Mapper 接口 + 1 个集成测试 = **5 个连带文件**。

共 11 个文件，核心组里的 XML Mapper 和 Java 业务类地位相同——
但实际上 XML Mapper 更接近「配置/mapping 层」，而 `ReconEngine.java` 是「核心算法」。
二分无法区分"这个 PR 最危险的文件是哪个"。

## 根因

`02-claude-plan.md` 的 Paths 二分设计来自 Go 场景：
- Go 项目一个文件 = 一个 package 的全部逻辑
- 测试文件 = `_test.go`，一律归连带组

Java Spring Boot 每个功能至少 5 层（entity / mapper-interface / mapper-xml / service / controller），
每层都有独立文件，二分不能区分层内的风险权重。

## 建议修复（starter v2.0）

在 `02-claude-plan.md` 中，对 Java 生态补充说明：

> **Java 多层说明**：若 Java/Spring Boot 项目的核心改动组超过 8 个文件，
> 可在核心改动组内用子标题区分「业务逻辑层」与「配置/映射层」：
>
> ```
> 核心改动（业务逻辑）:
> - src/main/java/.../engine/ReconEngine.java
> - src/main/java/.../service/ReconTaskService.java
>
> 核心改动（SQL/映射层，改动低风险但必须与上方对齐）:
> - src/main/resources/mapper/ReconDetailMapper.xml
> - src/main/resources/mapper/ReconTaskMapper.xml
>
> 连带改动（接口签名 / 测试）:
> - src/main/java/.../repository/ReconDetailMapper.java
> - src/test/java/.../engine/ReconEngineIntegrationTest.java
> ```

## 影响

- E1 本次 Slice task 文件已使用「统一核心/连带二分 + 代码注释区分风险」的变通方式
- 信号精度有损失，但 Codex 审校仍可接受
- 属于改进项，不阻塞当前 E1 流程
