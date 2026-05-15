---
finding: starter-v2-finding-06
slug: missing-spi-extensibility-question
date: 2026-05-13
severity: P1
---

# Finding 06 — intake 没有问出 SPI/插件扩展模型

## 现象

本项目有一个关键架构约束：E1 需要**骨架化** `ChannelAdapter` SPI 接口
（`channelCode / fetchFile / parse / normalize / onRealtimeNotify`），
以便 E2 扩展微信/银联时不改引擎核心。

```java
interface ChannelAdapter {
    String channelCode();
    ReconFile fetchFile(LocalDate date);
    Stream<ChannelRecord> parse(ReconFile file);
    NormalizedRecord normalize(ChannelRecord raw);
    void onRealtimeNotify(byte[] payload);   // E3
}
```

intake Q1-Q7 问题集没有一题涉及"扩展模型 / 插件 SPI / 抽象骨架设计"。
这个信息只能从 context.md 里读到，intake 流程本身无法探知。

## 影响

- 若 context.md 没有记录 SPI 设计，02-claude-plan 可能直接让 AlipayAdapter
  和引擎硬耦合（无 SPI 抽象），E2 时再解耦成本翻倍
- SPI 接口的稳定性也是一个 ADR 决策点（E2 之前 SPI 签名不能改变），
  但 intake 没问，就没机会锁定为"ADR 候选"
- context.md 说"ChannelAdapter SPI 改动需 ADR"——这是隐藏在 Key Boundaries 里的，
  intake 的问题集不会主动挖出来

## 建议

在 `intake-templates.md > §A Task Intake` 的 Q7（初始想法，仅 Large/Epic）下方，
增加一个「扩展性探针」问题（**Q8，仅当 Q2 = Large/Epic 时触发**）：

```
Q8. 本 Epic 是否预设了供后续 Epic 扩展的接口/插件/SPI 骨架？
  （例：适配器模式、策略模式、事件 hook、gRPC 服务接口预留）
  若有，E1/当前 Epic 需要同时完成骨架定义（哪怕只有一个实现）。
```

这个问题直接引导用户说出"E1 要做 ChannelAdapter 骨架"，
让 intake 产物里显式包含"扩展骨架"作为 In-scope 目标。

## 严重度

P1 — 明显摩擦。插件式架构（SPI / Strategy / Adapter 模式）在多渠道、多协议、
多数据源的批处理系统里极常见（本项目如此），但 intake 对这类结构性约束完全无感。
这也是 "starter 假设单服务单业务对象" 的隐藏假设在批处理/金融域的体现。
