---
finding-id: starter-v5.2-finding-25-rv-status-must-be-standard-value
severity: P2
category: prompt + template (04-review / 06-fix / review.md template)
source-project: DeviceOps
discovered: 2026-05-24
target:
  - .ai/review.md(template 顶部 Status semantics 段加禁止复合值)
  - .ai/prompts/04-review.md(收尾段提醒)
  - .ai/prompts/06-fix.md(收尾段提醒)
status: pending
related: []
---

# Finding 25: RV finding Status 字段必须用 7 种标准值之一,禁止自创复合状态

## 现象

DeviceOps M3-Beta S2 review fix 闭合时,Claude 为表达「fix 完成,但 E2E 证据要等 S4 转 verified」
这个**协议外**子状态,自创了 status 值 `fixed-with-deferred-E2E`(RV-20260524-04)。

实际 starter `.ai/review.md` 顶部 Status semantics 段已明文列出 7 种合法值:
> `open | accepted | in-progress | fixed | verified | rejected | deferred`

但模板**没明文禁止 Agent 自创第 8 种**,Claude 在写复杂多阶段闭合场景时容易越界。

## 影响

- 协议一致性破坏:grep 工具 / starter-status.sh 类脚本按 7 种 status 统计,自创值被漏算
- 跨 session resume 时,Pattern A 人 read 看到非标 status 不知如何对应到协议
- 长期累积 → review.md status 字段「自由格式漂移」(类比 Finding #02 state.md 字段漂移)

## 根因

review.md template 列了 7 种合法值,但没明文写:
- ❌ 「禁止自创第 8 种 status」
- ❌ 「需要表达子状态 / 承接路径时,放 Status 行括号注解」

04-review.md / 06-fix.md 收尾段也没提醒 Agent 用标准 status。

## 证据

- DeviceOps `.ai/review.md > RV-20260524-04` 整改前 Status 行:`Status: fixed-with-deferred-E2E`
- DeviceOps 整改后:`Status: **fixed**(S4 场景 2 跑通后由 Verifier 转 \`verified\`;此前不算 epic 闭合)`
- 第二种写法语义完全等价但协议合规

## 提议修复

### 1. `.ai/review.md` template 顶部 Status semantics 段

在现有列表后追加:

```markdown
**Status 字段只能用以上 7 种值之一**。需要表达 subtype / 承接路径 / 阶段闭合条件(如「fix 完成,等 E2E
验证转 verified」),放 Status 行的**括号注解**,**不要自创复合值**(典型反例:`fixed-with-deferred-X` /
`fixed-pending-Y` / `verified-conditional` 等)— 破坏 grep 与跨工具一致性。

正确写法示例:
- `Status: **fixed**(S4 场景 2 跑通后由 Verifier 转 verified;此前不算 epic 闭合)`
- `Status: **deferred**(GA brief 显式承接;本 epic 不修)`
- `Status: **verified**(随 RV-XX 闭合)`
```

### 2. `.ai/prompts/04-review.md` 收尾段 + `.ai/prompts/06-fix.md` 收尾段

加一句自检提醒:

```markdown
- 写入 review.md 时,Status 字段必须用 7 种标准值之一(`open / accepted / in-progress / fixed /
  verified / rejected / deferred`)。子状态 / 承接路径放 Status 行括号注解,**禁止自创复合值**。
```

## 优先级建议

- P2 = 中优先,可与 v5.2.x 其它 finding 一起 release
- lite v0.7.x review template 同步
