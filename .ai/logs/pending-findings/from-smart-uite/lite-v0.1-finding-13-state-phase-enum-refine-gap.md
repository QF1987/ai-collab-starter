---
finding-id: lite-v0.1-finding-13-state-phase-enum-refine-gap
severity: P3
category: template + doc
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/state.md (template "当前阶段" 字段注释段)
  - .ai/workflow.md (§0 4 终端拓扑 + 流转图段)
status: pending
related: [02]
---

# Finding 13: state.md 阶段枚举漏 "02-plan-refine / 03a-prep" 中间态, Codex 自创字符串导致枚举漂移

## 现象
smart-uite Daemon bug 修复 02 brief 通过后, Codex 没直接进 03a, 而是先写微 L2 req (req-daemon-singleton-2.md) 摸排 Daemon 测试基建 (响应 Human gate 补 1/补 2 要求)。

Codex 刷 state.md 时 `Last completed step.Step` 字段填 `03a-prep micro L2 req write`, `Active task.当前阶段` 填 `02-plan approved · micro L2 before 03a`。

**这两个字符串都不在 lite state.md template 注释里列出的阶段枚举内**。

template 当前注释 (`.ai/state.md` 顶部 Active task.当前阶段 行):
```
<!-- 02-plan / 03a-decompose / 03b-impl / 03c-verify / 04-review / merge / ... -->
```

枚举有 `02-plan` 和 `03a-decompose` 两个相邻项, 但没有覆盖 "02-plan 完成后, 03a 拆任务前, 中间又做了一轮 micro L2 摸排" 这种**精细化 02 阶段**的场景。

Codex 自创 `03a-prep` 和 `02-plan approved · micro L2 before 03a` 救场, 语义清楚但是枚举漂移。

## 影响
- 不严重 (P3) — Codex 自创可读, Human 也能 parse
- **但** lite 设计哲学是 "字段名 + 枚举值预先定义, 不让 Agent 自由发挥"; 多次自创会让 state.md 检查规则注释段 (Next step 段顶部那个) 失效, 因为校验规则只对枚举内的阶段触发
- 类似 Finding 02 字段名漂移问题的精细版, F02 是字段名漂移, F13 是字段**值**枚举漂移

## 根因
- `state.md` template `Active task.当前阶段` 字段注释只列了主线 6 个阶段 (`02-plan / 03a-decompose / 03b-impl / 03c-verify / 04-review / merge`), 没考虑**阶段间过渡 / 微 L2 / 微 review** 等真实跑出来的中间态
- `workflow.md` §0 阶段流转也是线性 6 段, 没建模"02 后 / 03a 前的精细化摸排"分支

## 证据
- 本对话 2026-05-18 00:46 后 Codex 写的 state.md 现状:
  - `当前阶段: 02-plan approved · micro L2 before 03a` (自然语言, 非枚举)
  - `Last completed step.Step: 03a-prep micro L2 req write` (自创枚举 `03a-prep`)
- 该自创没引起任何机器化校验失败 (因为 state.md template 校验规则只覆盖枚举内阶段), 但**Pattern A 后续 Agent / Human 读到这字段不知道该按哪条规则处理**

## 提议修复

### 1. **`state.md` template `Active task.当前阶段` 注释段** 扩展枚举:

```markdown
- 当前阶段: `NONE` <!-- 主线阶段 + 过渡态:
     02-plan         · Codex 出 brief
     02-plan-refine  · Codex 已出 brief 但需微 L2 / 用户反馈才能 finalize (新 v0.2)
     03a-decompose   · Codex 拆 OC-impl 子任务包
     03a-prep        · 03a 前的微 L2 / 补查 (新 v0.2)
     03b-impl        · OC-impl 写代码 (T3)
     03b-retry       · 03b 因 03c 退回重试 (轮次 X/3, 新 v0.2)
     03c-verify      · Codex 跑 rubric 验收
     04-review       · OC-review 三步法 (T4)
     04-fix-loop     · review 出 finding, OC-impl 修, OC-review 重审 (新 v0.2)
     merge           · Human 合入
     <stage>-human-gate · 任意阶段 Human 介入决策 (escalation / override, 新 v0.2)
     -->
```

### 2. **`workflow.md` §0** 加阶段流转图 (ASCII), 显式画出 5 个过渡态分支:

```
   ┌─────────┐    ┌──────────────┐    ┌──────────────┐
   │ 02-plan │──→│ 02-plan-refine│──→│03a-decompose │
   └────┬────┘    └──────────────┘    └────┬─────────┘
        │ (无须微 L2 时直接)                  │
        └─────────────→────────────────────→│
                                              ↓
                       ┌──────────────┐    ┌──────────────┐
                       │   03a-prep   │←──│03b-impl      │
                       │ (微 L2 补查) │    └────┬─────────┘
                       └──────┬───────┘         ↓
                              ↓            ┌──────────────┐
                       ┌──────────────┐    │ 03c-verify   │
                       │03a-decompose │←───┤ (3 轮上限)    │
                       └──────────────┘    └────┬─────────┘
                                                 ↓ pass
                                          ┌──────────────┐
                                          │  04-review   │
                                          └────┬─────────┘
                                               ↓ (无 finding)
                                          ┌──────────────┐
                                          │    merge     │
                                          └──────────────┘
   任意阶段 fail → <stage>-human-gate → human override 三选 (a)(b)(c)
```

### 3. **关联 Finding 02 (state.md 字段漂移)**: F02 修了字段**名**, F13 修字段**值** (阶段枚举)。两个一起修能让 state.md 完整可机器化校验。

## SemVer 影响
**PATCH** (枚举扩展, 不破坏 v0.1 现有 6 阶段语义, 新加 5 个过渡态值; 现有 derived 项目 state.md 不需要 migrate, 旧值仍合法)。
