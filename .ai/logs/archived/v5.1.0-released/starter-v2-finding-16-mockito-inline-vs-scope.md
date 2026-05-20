---
finding: starter-v2-finding-16
slug: mockito-inline-vs-scope
phase: 03-codex-implement
date: 2026-05-13
severity: P2
---

# Finding 16 — task 要求 Mockito mock,但本机 Mockito inline 初始化失败且修复文件不在 Scope.paths

## 现象

`E1-S2-alipay-channel-adapter.md` 要求 `AlipayChannelAdapterTest` 使用 Mockito mock `FileFetcher`。
实际运行 `mvn test -Dtest=AlipayCSVParserTest,AlipayChannelAdapterTest` 时,Mockito 初始化失败:

```text
Could not initialize inline Byte Buddy mock maker
Could not self-attach to current VM using external process
```

## 根因

Spring Boot 3.3 的测试依赖默认使用 Mockito inline mock maker;当前 macOS/JDK 组合不支持
Byte Buddy self-attach。常见修复是新增:

```text
src/test/resources/mockito-extensions/org.mockito.plugins.MockMaker
```

并写入 `mock-maker-subclass`。

但该路径不在 Slice 2 task 的 `核心改动 paths` / `连带改动 paths` 内。

## 处理

Codex 本轮未越界新增 Mockito 扩展配置,改为在 `AlipayChannelAdapterTest` 内使用手写
`RecordingFileFetcher` fake,保留"验证 adapter 委托 FileFetcher"的行为覆盖。

## 建议

starter task 模板若要求某测试框架特性,应把对应测试配置文件路径纳入 Scope.paths;
或允许在本地环境不支持 inline mock maker 时使用手写 fake 替代 Mockito。

---

## main v5.1.0-rc1 处置 (2026-05-20)

**已实现** — main `02-claude-plan.md` AC↔Scope.paths 校验段已显式含本 finding 修复 (mockito-extensions 配置文件纳入 Scope.paths)。无需再做。
