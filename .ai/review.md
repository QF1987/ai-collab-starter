# Review Log

This file tracks review findings across Scout, Claude Code and Impl fix cycles.

## Review Policy

- Scout performs low-cost review first.
- Claude Code reviews architecture-sensitive or high-risk changes.
- Impl fixes only approved findings and reruns targeted verification.
- Review output must identify file, line or symbol whenever possible.

## Finding Format

```markdown
## RV-YYYYMMDD-NN: <short title>

- Severity: P0/P1/P2/P3
- Reporter: 提出方（Scout | Claude Code | Human | CI）
- Owner: 修复责任 Agent（Claude / Impl / Scout / Human）
- Verifier: verify 责任方，默认与 Reporter 相同
- Repo: <repo 标识 / 路径>
- File/symbol: <精确定位>
- Status: open | accepted | in-progress | fixed | verified | rejected | deferred
- Finding: <现象 + root cause>
- Expected fix: <策略>
- Verification: <如何确认修好——命令 / 真机步骤 / 测试名>
```

## Status semantics

- `open`: 已记录，未分诊
- `accepted`: 已确认需修复，分配 owner
- `in-progress`: 修复中
- `fixed`: 修复完成，等待 verify
- `verified`: 提出方已验证通过
- `rejected`: 评估后不修
- `deferred`: 延后处理（注明原因）

**关闭规则**：finding 必须由 Reporter（不是 fix 实施人）翻 `verified` 才算关闭。P0/P1 未 verified 不得合并。

## Severity

- **P0**: data loss / security break / fleet-wide outage / release blocker
- **P1**: production bug / protocol incompatibility / serious lifecycle or concurrency risk
- **P2**: correctness issue / missing test / important maintainability problem
- **P3**: style / docs / small cleanup / optional improvement

---

<!-- Agent 追加新 finding 开始 -->
