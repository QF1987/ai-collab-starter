---
finding: 12
slug: adr-data-contract-missing-entity-mapper-level
phase: 02-claude-plan
date: 2026-05-13
severity: medium
---

# Finding 12: ADR 数据契约三级对 Java ORM 生态缺少「实体注解级」和「Mapper 接口级」

## 现象

`02-claude-plan.md` 要求数据契约分三级：

1. **列语义级**：某列的值含义不变
2. **表结构级**：某表的列结构（不加新列 / 不删现有列）
3. **数据级**：数据迁移 / backfill 策略

这三级对 **DB schema 层** 的约束完整。

但在 Java + MyBatis 生态中，还有两个额外的约定层：

4. **实体注解级**（Entity annotation level）：
   Java entity 类的字段名与 DB 列名之间的映射关系（`@Results`/`resultMap`），
   可以**不改 DDL、不改值语义**，只改 entity 字段名，就导致 MyBatis 映射失败。
   这在三级模型中不可见。

5. **Mapper 接口级**（Mapper interface level）：
   `ReconTaskMapper.java` 的方法签名是下游 Service 的调用合约。
   Slice 3 新增 `updateStatus(Long id, String status, List<String> allowed)` 方法后，
   Slice 4 必须调用，但如果 Slice 3 改了签名（如改为 `updateStatus(Long id, TaskStatus status)`），
   Slice 4 代码编译失败。这在三级模型中也不可见。

## 根因

三级数据契约模型来自 Go/protobuf 场景，关注的是 **wire format（网络传输格式）**的兼容性，
不关注 ORM 层的中间映射。

Java/MyBatis 生态在 DB schema 和业务逻辑之间多了两层：
- entity class（Java 字段 ↔ DB 列的映射）
- Mapper interface（Java 方法 ↔ XML SQL 的映射）

这两层本身就是"数据契约"，跨 Slice 改动时一样会造成 Codex 越界和合并冲突。

## 影响案例（本 E1 已预见的风险）

- Slice 1 写了 `ReconTaskMapper.insert(ReconTask)` stub
- Slice 3 要新增 `updateStatus()` 方法
- Slice 3 Codex 必须修改 Slice 1 产出的 `ReconTaskMapper.java`（连带改动）
- 如果 Slice 3 ADR 没有显式列出这个文件的改动范围，Codex 审校时会不确定是否越界

本 E1 已通过在 Slice task 文件中显式列出 `ReconTaskMapper.java` 为连带改动路径来缓解。

## 建议修复（starter v2.0）

在 `02-claude-plan.md` 的「数据契约约束分三级」章节末尾追加 Java 生态补充说明：

> **Java ORM 生态额外两级（如适用）**：
>
> 4. **（实体注解级）** entity class 的字段名与 DB 列名映射（`@Results`/`resultMap`）：
>    禁止跨 Slice 单方面改 entity 字段名而不同步改 XML resultMap，
>    等效于改调用者 API。
>
> 5. **（Mapper 接口级）** Mapper Java 接口的方法签名是 Service 层的调用合约：
>    新增方法不破坏已有调用；改方法参数类型/返回类型须在 ADR 中声明，
>    与 L2（不兼容改动）同等对待。

## 影响

- 当前 E1 的 ADR 已在 decisions.md 中手动补了「实体注解级」和「Mapper 接口级」条目
- 属于模板级别的系统性改进，建议进入 starter v2.0 ADR 章节
