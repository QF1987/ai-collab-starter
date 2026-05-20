---
finding-id: lite-v0.6-finding-06-codex-direct-solve-mode-not-formalized
severity: P3
category: workflow + escalation-pattern-gap
source-project: smart-uite (bug-20260519-h5coat-white-screen-network-path · Human override「你自己干吧」非成文模式)
discovered: 2026-05-20
target:
  - .ai/workflow.md (新增 escalation 模式「Codex direct-solve mode」)
  - .ai/state.md (阶段枚举: <stage>-human-gate 子模式加 codex-direct-solve)
  - .ai/prompts/02-codex-plan.md (human-gate 三选项之一引用 direct-solve)
status: pending
related: [F04-v0.6, F05-v0.6]
---

# Finding F06-v0.6: Human override「你自己干吧」是有效但未成文的 escalation 模式, 应正式化为「Codex direct-solve mode」

## 现象

smart-uite `bug-20260519-h5coat-white-screen-network-path` epic R1-R5 五轮诊断无果后, Human 直接喊:

```
太多轮没有解决了，你自己干吧！
```

Codex 收到这句话后, **脱离 lite 的 4-track 编排** (不再 03a 拆包 / 03b OC-impl 写 / 03c 验收), 自己:
1. 翻历史归档 (qt5core-missing epic 的未验证嫌疑)
2. 基于 local-vs-remote 差分推理出根因
3. 直接出 patch (StageTdmRuntime.cmake 写 qt.conf)
4. 一轮解决

效果非常好——但这是个**临时口头模式**, lite contract 里没有它。

## 影响

- **有效模式未沉淀**: 「诊断循环 stall → Codex 脱编排直接推理+修复」是个被验证有效的 escalation 出口, 但因为没成文, 每次都靠 Human 临场口头触发
- **触发时机靠运气**: 本次是资深 Human 凭直觉在第 5 轮喊停。生产环境用户可能第 10 轮还在拆包, 或者根本不知道可以「让 Codex 自己干」
- **没有边界约束**: 「Codex 自己干」绕过了 03b/03c/04 的 scope 强约束 / rubric 验收 / review。本次结果对 (因为后面补了 OC-review 04), 但若没补 review, direct-solve 出的 patch 就没有质量门。模式需要明确「绕过哪些 / 必须补哪些」

## 根因

lite 的 escalation 机制只有 `<stage>-human-gate` (Human 介入决策) 这一个通用态, 没有细分出「Codex direct-solve」这种**具体处置模式**。Human override 后 Codex 怎么做、做完怎么回归正常流程 (补 review / 补 closeout), 全靠 Codex 自由发挥。

## 证据

- smart-uite `bug-20260519-h5coat-white-screen-network-path` conversation 归档第 9 段「Human override: Codex 直接接手」: Human 原话「太多轮没有解决了, 你自己干吧」, Codex 接手后翻归档 + 差分推理 + 直接出 patch
- 第 13 段: direct-solve 出 patch 后, Human 仍补了 OC-review 04 (0 P0/P1, 2 P3) —— 说明 direct-solve **后面接回了正常 review/closeout**, 这个回归动作本次做对了, 但纯属 Human 经验, 没契约保证

## 提议修复

### 1. `workflow.md` 新增 escalation 模式「Codex direct-solve mode」

```markdown
## Escalation 模式: Codex direct-solve mode (v0.6 · F06-v0.6)

触发: 诊断型 epic 达 F04-v0.6 诊断轮上限 (3 轮无收敛), 02-human-gate 选项 (a);
      或 Human 显式说「Codex 你自己干」。

模式定义:
- Codex 脱离 03a/03b/03c 4-track 编排, 在 T1 直接: 翻历史归档 → 推理 → 出最小 patch
- direct-solve 期间允许 Codex 直接改代码 (不经 OC-impl), 但仍受 scope 约束:
  只动诊断已收窄指向的 paths, 单 patch 优先 ≤ 50 行
- **必须回归正常质量门**: direct-solve 出 patch 后, 强制补 04 OC-review (不可跳过) +
  09 closeout。review 出 P0/P1 → 正常 04-fix-loop
- state.md 阶段标 `02-human-gate · codex-direct-solve`

不允许: direct-solve 跳过 04 review 直接 merge。
```

### 2. `state.md` 阶段枚举加子模式

```
<stage>-human-gate   · 任意阶段 Human 介入决策 (escalation / override)
                       子模式 codex-direct-solve: 诊断 stall 后 Codex 脱编排直接修 (v0.6 · F06-v0.6)
```

### 3. `02-codex-plan.md` human-gate 三选项引用 direct-solve

F04-v0.6 已在 02-human-gate 列三选项, 选项 (a) 即 direct-solve, 此处加 workflow.md 锚点引用。

## SemVer 影响

**MINOR** (新增 escalation 模式 + state 阶段子模式 · 不破坏 v0.5 旧 epic · 纯增量; 把已验证有效的 ad-hoc 模式成文, 风险低收益明确)。

## 关联

- 与 **F04-v0.6 (诊断轮次上限)** 强协同: F06 是 F04 human-gate 选项 (a) 的处置定义
- 与 **F05-v0.6 (differential signal)** 协同: direct-solve 的核心动作 (差分推理) 就是 F05 想前移到正常流程的能力——理想情况 F05 生效后 direct-solve 触发率下降
- 与 **F03-v0.6 (历史归档检索)** 协同: direct-solve 第一步「翻历史归档」正是 F03 想前移到 01-intake 的动作
- 观察: F03/F04/F05 若都生效, F06 的 direct-solve 应成为罕见兜底, 而非常规出口

## 实施记录 (v0.6.0-lite-rc1)

- `workflow.md`: 新增 `## 11. Escalation 模式: Codex direct-solve mode` 段 (触发 / 模式定义 / scope 约束 ≤ 50 行 / 强制补 04 review + 09 closeout)。
- `state.md` 阶段枚举: `<stage>-human-gate` 加子模式 `codex-direct-solve` 注释。
- `02-codex-plan.md > 诊断型 epic 强约束`: human-gate 选项 (a) 引用 workflow.md §11 direct-solve 锚点。
- commit: v0.6.0-lite-rc1 release commit (见 CHANGELOG)。
