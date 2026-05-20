---
finding-id: lite-v0.6-finding-05-differential-signal-not-prioritized
severity: P2
category: prompt + diagnostic-method-gap
source-project: smart-uite (bug-20260519-h5coat-white-screen-network-path · local-static PASS / remote FAIL 分化出现后仍继续广矩阵)
discovered: 2026-05-20
target:
  - .ai/prompts/02-codex-plan.md (诊断指引段加「differential signal 优先」原则)
  - .ai/prompts/03-codex-orchestrate.md (03a 拆诊断包时加「分化出现 → 收窄」约束)
  - .ai/workflow.md (诊断循环收敛规则段同步)
status: pending
related: [F04-v0.6, F06-v0.6]
---

# Finding F05-v0.6: 缺「differential signal 优先」诊断原则, PASS/FAIL 分化出现后仍继续广撒网矩阵

## 现象

smart-uite `bug-20260519-h5coat-white-screen-network-path` epic, 在 R4 (OpenGL Attribute / Runtime Fingerprint) 轮, 矩阵第一次出现明确的 **PASS/FAIL 分化信号**:

```
baidu-diag-gl-opengles: FAIL
gl-desktop: FAIL
gl-software: FAIL
gl-none: FAIL
Matrix exit code: 0 (local-static PASS)   ← local-static 开始 PASS, remote 仍 FAIL
```

Codex R4 结论已经注意到:「local-static 开始 PASS, 但 remote/simple-http/baidu 仍 FAIL」。**但下一步 (R5) 仍然去跑了 LocalDumps / PE Offset Mapping 这种广角诊断**, 而不是立刻针对「local PASS vs remote FAIL」这个差分做最小 A/B。

Human override 后, Codex 正是靠这个差分秒推出来:

```
local-static PASS, remote/simple-http/baidu FAIL
→ 不是整体 WebEngine 坏
→ remote navigation 才触发 renderer breakpoint
→ 子进程独立解析 Qt resources 失败 → 缺 runtime-bin qt.conf
```

也就是说: **决定性的差分信号在 R4 就出现了, 但 contract 没要求「分化出现 → 停广矩阵 → 推差分」, 于是又浪费了 R5 一整轮。**

## 影响

- **差分信号被忽略**: 诊断最有价值的时刻是「出现 PASS/FAIL 分化」, 此时根因范围已被实验数据收窄。继续广矩阵是浪费
- **多烧至少一轮 Windows VM 矩阵**: R5 LocalDumps + PE parser (还 REJECT 重跑一次) 本可跳过
- **诊断方法论缺失**: lite 02-plan 教 Codex「列 alternatives ≥ 2 / Assumptions」, 但没教「实验数据出现分化时如何收窄」——这是诊断的核心技能, 却没成文

## 根因

`02-codex-plan.md` 的诊断指引强调「区分 N 个根因类别」(广度), 但没有「一旦实验出现 PASS/FAIL 分化, 暂停扩矩阵, 优先针对差异维度做最小 A/B」(收敛) 的原则。

`03-codex-orchestrate.md` 03a 拆诊断子任务包时, 也没约束「若上一轮已出现分化, 本轮必须是收窄型 A/B 而非又一个广矩阵」。

## 证据

- smart-uite `bug-20260519-h5coat-white-screen-network-path` conversation 归档第 7 段 (R4): Codex 结论明确写「local-static 开始 PASS, 但 remote/simple-http/baidu 仍 FAIL」「问题进一步收窄到 remote navigation / QtWebEngine child process runtime context」
- 第 8 段 (R5): 下一步仍是 LocalDumps / PE Offset Mapping 广角诊断, 没针对 local-vs-remote 差分做 A/B
- 第 9 段 (override): Codex 用同一个 local-vs-remote 差分一步推到根因

## 提议修复

### 1. `02-codex-plan.md` 诊断指引加「differential signal 优先」原则

```markdown
## 诊断方法: differential signal 优先 (v0.6 · F05-v0.6)

诊断型 epic 每轮 matrix 结果回来后, Codex 必须先做**分化检查**:

- 是否出现 PASS/FAIL 分化? (某些 case PASS / 某些 FAIL)
- 是否排除了一整类根因? (某维度全 PASS / 全 FAIL 无影响)

**一旦出现分化信号**:
1. 立即停止「再开一个广角矩阵」的冲动
2. 显式写出分化两侧的**唯一变量** (e.g. local-static vs remote = 「子进程是否需独立解析 runtime」)
3. 下一轮必须是**针对该唯一变量的最小 A/B** (改一个文件 / 一个配置, 跑前后对照), 不是又一个广矩阵
4. 该最小 A/B 算「强收敛」, 满足 F04-v0.6 的轮次放宽条件

无分化信号 (全 FAIL 无差异) → 才允许继续换广角维度。
```

### 2. `03-codex-orchestrate.md > 03a` 加「分化出现 → 收窄」约束

```markdown
(v0.6 · F05-v0.6) 03a 拆诊断子任务包前, 检查上一轮 brief 是否记录了 PASS/FAIL 分化。
若有 → 本轮子任务包必须是针对分化唯一变量的收窄型 A/B, 禁止拆又一个广角矩阵包。
```

### 3. `workflow.md` 诊断循环收敛规则段同步「分化 = 强收敛」定义

与 F04-v0.6 的 workflow.md 段合并维护。

## SemVer 影响

**MINOR** (新增诊断方法论原则 + 03a 收窄约束 · 不破坏 v0.5 旧 epic · 纯增量指引)。

## 关联

- 与 **F04-v0.6 (诊断轮次上限)** 强协同: F05 定义「分化 = 强收敛」, F04 用它判断轮次是否放宽
- 与 **F03-v0.6 (历史归档检索)** 协同: 都是「让诊断早点收敛, 别广撒网烧矩阵」
- 与 **F06-v0.6 (Codex direct-solve)** 协同: Codex override 一步解决靠的就是差分推理, F05 把这个能力前移到正常流程

## 实施记录 (v0.6.0-lite-rc1)

- `02-codex-plan.md > 诊断型 epic 强约束`: 新增 `### 诊断方法: differential signal 优先` (分化检查 → 写唯一变量 → 下一轮最小 A/B → 算强收敛)。
- `03-codex-orchestrate.md`: 新增 `### 03a 诊断型子任务包: 分化出现 → 收窄` (上一轮有分化 → 本轮必须收窄型 A/B, 禁止广角矩阵)。
- `workflow.md > §10.3`: differential signal 优先写入诊断循环收敛规则段, 与 F04-v0.6 合并维护 (分化 = 强收敛)。
- commit: v0.6.0-lite-rc1 release commit (见 CHANGELOG)。
