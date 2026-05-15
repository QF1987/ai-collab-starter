---
finding: starter-v2-finding-18
slug: e2e-fixture-setup-guidance
phase: 03-codex-implement
date: 2026-05-14
severity: P3
---

# Finding 18 — 03-codex-implement 对后端 E2E fixture 编排缺少明确约束

## 现象

Slice 4 首次引入完整 `@SpringBootTest + MockMvc + Testcontainers + 本地文件 fixture + DB seed`
链路。task 文件给出了业务级 setup 要求,但 `03-codex-implement.md` 只要求跑测试与记录结果,
没有提供后端 E2E 的机器证据模板,例如:

- fixture 复制/命名路径必须与运行时 `LocalFileFetcher` 约定一致
- HTTP response JSON 与 DB 行数需同时作为验收证据
- Testcontainers 需记录 Flyway migration applied 与容器版本
- 失败路径要验证 HTTP 错误和持久化状态两侧结果

## 影响

在批处理/文件驱动型项目中,仅写“mvn test PASS”容易漏掉 fixture 实际来源、HTTP body 与 DB
副作用之间是否一致。该问题正好具体化了 Finding 05 中“批处理域机器证据”缺少落点的问题。

## 建议

starter v2.0 可在 `03-codex-implement.md` 增加“后端 E2E 证据”小节:

1. 列出测试 fixture 来源与运行时路径映射
2. 记录关键 HTTP status / JSON 字段断言
3. 记录关键 DB 行数或状态断言
4. 对 Testcontainers 场景记录镜像版本与 Flyway applied 证据
