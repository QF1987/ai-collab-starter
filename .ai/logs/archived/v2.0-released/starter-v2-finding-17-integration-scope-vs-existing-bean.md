---
finding: starter-v2-finding-17
slug: integration-scope-vs-existing-bean
phase: 03-codex-implement
date: 2026-05-13
severity: P2
---

# Finding 17 — Slice 3 集成测试会暴露 Slice 2 bean 构造器问题,但修复文件不在 Scope.paths

## 现象

`ReconEngineIntegrationTest` 若直接继承默认 `AbstractIntegrationTest` 的完整 `@SpringBootTest`
应用上下文,Spring 会加载 Slice 2 的 `AlipayChannelAdapter` bean,并报错:

```text
Failed to instantiate AlipayChannelAdapter: No default constructor found
```

原因是 `AlipayChannelAdapter` 当前有一个 public 单参构造器和一个 package-private 双参测试构造器,
未显式标注 `@Autowired` 时,Spring 在该上下文下没有选择 public 构造器。

## Scope 冲突

最直接修复是修改:

```text
src/main/java/com/alcedo/paymentrecon/adapter/alipay/AlipayChannelAdapter.java
```

例如给 public 构造器加 `@Autowired` 或调整测试构造器可见性。但该文件不在
`E1-S3-recon-engine.md` 的核心/连带改动 paths 中。

## 本轮处理

Codex 未越界修改 `AlipayChannelAdapter.java`。`ReconEngineIntegrationTest` 改为启动最小测试上下文:

- Spring Boot auto-configuration
- `MyBatisConfig`
- `ReconEngine`

测试内手动构造 `ReconTaskService` 并注入 fake `ChannelAdapter`,从而只验证 Slice 3 范围内的
mapper / engine / service / transaction 行为。

## 建议

starter task 模板应在集成测试要求完整 `@SpringBootTest` 时,允许把前序 slice 中已发现的
bean wiring 修复文件纳入 `连带改动 paths`;否则 Agent 会在"修真实启动问题"和"守 scope"之间冲突。
