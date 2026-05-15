---
finding: starter-v2-finding-15
slug: scope-vs-acceptance-application-test
phase: 03-codex-implement
date: 2026-05-13
severity: P2
---

# Finding 15 — task Scope.paths 与 Acceptance Criteria 对 application-test.yml 要求冲突

## 现象

`E1-S2-alipay-channel-adapter.md` 的 `Acceptance Criteria` 要求:

> `LocalFileFetcher` 的 `@Value` 配置字段在 `application-test.yml` 中有对应值

但该 task 的 `核心改动 paths` + `连带改动 paths` 只允许修改:

- `src/main/resources/application.yml`
- adapter / model 源码
- Slice 2 单元测试与 CSV fixture

`src/test/resources/application-test.yml` 不在允许改动范围内。

## 影响

Codex 在严格遵守 task Scope 时不能补 `application-test.yml`;若为了满足 AC 直接修改,
又会违反 AGENTS.md 的 scope 越界纪律。该冲突会迫使 Agent 在"守 scope"和"守 AC"之间二选一。

## 建议

starter task 模板生成 Acceptance Criteria 时应校验每个要求涉及的文件都已列入 Scope.paths。
若 AC 需要修改测试 profile,应把 `src/test/resources/application-test.yml` 放入连带改动 paths。
