---
finding-id: lite-v0.1-finding-06-severity-escalation-mapping
severity: P3
category: doc
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/getting-started.md (§三 差异 1 Bug Brief 模板)
status: pending
related: []
---

# Finding 06: Bug Brief Severity ↔ human-escalation-suggested 默认映射没说

## 现象
本次 smart-uite Bug Brief 我帮用户起草时, 标 `severity: P1, human-escalation-suggested: true`, 但 lite getting-started.md §三 差异 1 Bug Brief 模板里**没说明"什么 severity 默认配什么 escalation 标记"**。

用户没问起这事, 我也是凭经验填 (P0/P1 → true, P2/P3 → false), 但 lite 文档没固化, 下游 Agent / Human 不知道默认是啥。

## 影响
- 不严重 (P3) — 经验值就能对付
- 但每次都靠经验, 漂移可能 (e.g. 某次 P1 标 false, 跳过 Human gate, 导致严重 bug 直接进 03b)

## 根因
`getting-started.md §三 差异 1 Bug Brief 模板` 当前:
```markdown
---
task-id: bug-<date>-<slug>
size: ...
severity: P0 | P1 | P2 | P3
human-escalation-suggested: <若 P0/P1 通常 true>
created: YYYY-MM-DD
---
```

`human-escalation-suggested` 字段值用 "通常 true" 字面值, 不是规则。

## 证据
本对话 Step 1 我起草 Bug Brief 时凭经验填 P1 + true, 没引用任何 lite 文档段落, 因为没有可引用的规则。

## 提议修复
**`getting-started.md §三 差异 1`** 模板下方加一段:
```markdown
### Severity → human-escalation-suggested 默认映射

| Severity | 默认 `human-escalation-suggested` | 例外情况 |
| --- | --- | --- |
| P0 (线上事故 / 阻塞用户 / 数据损坏) | `true` | 紧急通道明确跳 02 → minimal hotfix 时 false |
| P1 (功能错乱 / 体验严重影响 / 资源冲突) | `true` | 修复路径明确单选, Human 不需介入决策时 false |
| P2 (功能瑕疵 / 边界 case 错误) | `false` | 涉及架构敏感字段 (注解 / SPI / 配置结构) 改 true |
| P3 (typo / 文档 / 不影响行为) | `false` | 改 lite 框架本身 prompt 时 true (走 lite-upgrade-protocol) |

不严格强制, 但偏离默认时**必须在 brief 末尾 "Why this severity-escalation combination" 段说明理由**。
```

## SemVer 影响
**PATCH** (纯文档增补, 不改 prompt 契约)。
