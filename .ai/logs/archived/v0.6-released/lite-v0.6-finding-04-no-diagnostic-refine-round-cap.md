---
finding-id: lite-v0.6-finding-04-no-diagnostic-refine-round-cap
severity: P2
category: prompt + workflow-convergence-gap
source-project: smart-uite (bug-20260519-h5coat-white-screen-network-path · 02-plan-refine R1-R5 无轮次上限)
discovered: 2026-05-20
target:
  - .ai/prompts/02-codex-plan.md (02-plan-refine 段加诊断轮次上限 + 收敛 gate)
  - .ai/state.md (阶段枚举: 02-plan-refine 加轮次标注 R<X>/3; 维护规则补诊断轮 cap)
  - .ai/prompts/03-codex-orchestrate.md (03c 验收若识别「诊断无收敛」, 触发 human-gate)
  - .ai/workflow.md (§诊断循环收敛规则新增段)
status: pending
related: [F03-v0.6, F05-v0.6, F06-v0.6]
---

# Finding F04-v0.6: 02-plan-refine 诊断循环没有轮次上限 / 收敛 gate, 靠 Human 手动喊停

## 现象

smart-uite `bug-20260519-h5coat-white-screen-network-path` epic 的 02-plan-refine 跑了 **R1 → R2 → R3 → R4 → R5 五轮诊断** (每轮: Codex 出新诊断角度 → OC-impl 跑 Windows VM 矩阵 → 结果 FAIL → 再来一轮):

- R1 Diagnostic Matrix (URL/proxy/cert/disable-gpu)
- R2 Diagnostic Instrumentation (renderer process)
- R3 Renderer Crash Triage (Qt5WebEngineCore.dll / 0x80000003)
- R4 OpenGL Attribute / Runtime Fingerprint
- R5 LocalDumps / PE Offset Mapping

五轮都没修复白屏。最终是 **Human 手动喊停**:

```
太多轮没有解决了，你自己干吧！
```

Codex override 后一轮解决 (见 F03-v0.6 / F06-v0.6)。

## 影响

- **诊断循环无上限**: lite 的 03b-impl 有明确 `轮次 X/3` retry cap (3 轮 fail 升 Human), 但 **02-plan-refine 的诊断轮完全没有 cap**, 可以无限跑
- **靠 Human 经验兜底**: 本次是资深 Human 凭直觉喊停。生产环境 derived 项目用户没这个直觉, 诊断循环会一直烧 Windows VM 矩阵 (每轮一次完整 matrix run, 成本高)
- **没有「收敛 gate」**: 每轮换一个诊断角度, 但没有契约要求「第 N 轮无收敛 → 强制停下复盘 / 换策略 / 升 Human」
- **成本不对称放大**: 修复极小 (写一个 qt.conf), 但因为缺 cap, 花了 5 轮昂贵 instrumentation

## 根因

`02-codex-plan.md` 的 02-plan-refine 路径只规定「需微 L2 / 用户反馈才能 finalize」, 没规定**诊断轮次上限**, 也没规定**无收敛时的强制 gate**。

`state.md` 阶段枚举里 `02-plan-refine` 没有像 `03b-retry` 那样带 `轮次 X/3` 标注, 所以 Human / Agent 都看不到「已经第几轮了」。

`03-codex-orchestrate.md` 的 03c 验收能 REJECT 单轮诊断包 (本次 R1/R5 各 REJECT 一次), 但 03c 没有「跨轮视角」——它不会因为「这是第 5 轮且仍无收敛」而触发 human-gate。

## 证据

- smart-uite `bug-20260519-h5coat-white-screen-network-path` conversation 归档第 3-9 段: R1-R5 五轮明确编号, 每轮 FAIL, 第 9 段 Human override
- 归档显示 R1 因 INI section 写错被 03c REJECT, R5 PE parser 因只解析 1 section 被 03c REJECT —— 03c 在「单轮质量」上工作正常, 但没有「跨轮收敛」判断
- 对比: 03b-opencode-impl.md 已有 `轮次 X/3` 上限契约 (3 轮 fail 输出「达到 3 轮上限, 升 Human 决策」)

## 提议修复

### 1. `02-codex-plan.md > 02-plan-refine` 加诊断轮次上限 + 收敛 gate

```markdown
## 02-plan-refine 诊断轮次上限 (v0.6 · F04-v0.6)

诊断型 refine (每轮换角度 + 跑 instrumentation/matrix 验证) **最多 3 轮**。

每轮结束 Codex 必须在 brief 标注:
- 当前轮次 `诊断轮 R<X>/3`
- 本轮是否产生**收敛信号** (排除了某个根因类别 / 出现 PASS-FAIL 分化 / 缩小了嫌疑范围)

**第 3 轮结束仍无收敛 → 强制进入 `02-human-gate`**, 不允许开 R4。
human-gate 给 Human 三个选项:
- (a) 切「Codex direct-solve mode」(见 F06-v0.6) —— Codex 脱离编排直接推理+修复
- (b) 外部审计 (Claude / 资深工程师)
- (c) Human 提供新 evidence 后显式批准再开一轮

例外: 若某轮明确**排除了一整类根因**或**出现强差分信号** (见 F05-v0.6), 算「有收敛」, 轮次计数可放宽, 但仍需在 brief 显式论证「为什么这轮算收敛」。
```

### 2. `state.md` 阶段枚举 `02-plan-refine` 加轮次标注

```
02-plan-refine        · brief 已出但需微 L2 / 诊断 (诊断型必标 诊断轮 R<X>/3, v0.6 · F04-v0.6)
```

### 3. `03-codex-orchestrate.md > 03c` 加跨轮收敛检查

```markdown
(v0.6 · F04-v0.6) 03c 验收诊断型子任务包时, 若发现「已是第 3 轮诊断且本轮 matrix 仍全 FAIL 无新收敛」,
即使本轮诊断包质量 PASS, 也必须在 chat 标「诊断已达 3 轮无收敛, 建议触发 02-human-gate」, 不直接开下一轮。
```

### 4. `workflow.md` 新增「诊断循环收敛规则」段

把上述 3 轮上限 + 收敛定义 + human-gate 三选项写入 workflow.md, 作为跨 prompt 的 SoT。

## SemVer 影响

**MINOR** (新增诊断轮上限契约 + state 阶段标注 + 03c 跨轮检查 · 不破坏 v0.5 旧 epic · 旧 epic 无轮次标注仍合法; 对生产环境「诊断循环失控」是实质风险 → 建议优先实施)。

## 关联

- 与 **F03-v0.6 (历史归档检索)** 协同: F03 让早期就翻历史减少轮数, F04 给轮数兜底硬上限
- 与 **F05-v0.6 (differential signal 优先)** 协同: F05 定义「什么算收敛」, F04 用它做轮次放宽判断
- 与 **F06-v0.6 (Codex direct-solve mode)** 协同: F06 是 F04 human-gate 的选项 (a) 出口
- 跨 epic 历史: 03b-impl 早有 X/3 cap, 但 02-plan-refine 诊断轮一直裸奔, 本次首次被 Human 显式 catch

## 实施记录 (v0.6.0-lite-rc1)

- `02-codex-plan.md`: 新增 `## 诊断型 epic 强约束` 段, 含 `### 02-plan-refine 诊断轮次上限 + 收敛 gate` (最多 3 轮, 第 3 轮无收敛强制 02-human-gate, 三选项)。
- `state.md` 阶段枚举: `02-plan-refine` 加 `诊断型必标 诊断轮 R<X>/3` 标注。
- `03-codex-orchestrate.md`: 新增 `### 03c 诊断型子任务包: 跨轮收敛检查` (第 3 轮全 FAIL 无收敛即使单轮 PASS 也建议触发 human-gate)。
- `workflow.md`: 新增 `## 10. 诊断循环收敛规则` 段 (轮次上限 + 收敛定义 + human-gate 三选项, 跨 prompt SoT)。
- commit: v0.6.0-lite-rc1 release commit (见 CHANGELOG)。
