---
finding-id: lite-v0.6-finding-03-no-prior-epic-archive-scan
severity: P1
category: prompt + critical-diagnostic-gap
source-project: smart-uite (bug-20260519-h5coat-white-screen-network-path · R1-R5 五轮诊断后 Human override 才解决)
discovered: 2026-05-20
target:
  - .ai/prompts/01-codex-intake.md (Step 1.5 Evidence ingestion 段加「同组件历史归档检索」子步)
  - .ai/prompts/02-codex-plan.md (Assumptions to verify 段加「历史未验证嫌疑优先」硬约束)
  - .ai/prompts/09-codex-closeout.md (归档时强约束「未验证嫌疑 / 残留 follow-up」单独成段, 便于后续 grep)
status: pending
related: [F01-v0.5, F04-v0.6]
---

# Finding F03-v0.6: 01-intake / 02-plan 没有强制检索同组件历史 epic 归档的「未验证嫌疑」, 导致已知答案被埋, 重新走 5 轮诊断

## 现象

smart-uite `bug-20260519-h5coat-white-screen-network-path` epic 走了 R1→R5 五轮诊断 matrix (每轮一次 Windows VM 矩阵跑) + 初始 slice + Human override 才解决。最终根因极小:

```
QtWebEngineProcess.exe 同目录缺 runtime-bin qt.conf
修复: StageTdmRuntime.cmake 生成 runtimes/qt-5.15.2/bin/qt.conf (写一个文件)
```

**关键**: 这个根因 **在上一个 epic `bug-20260519-h5coat-qt5core-missing` 的归档里就被记下来了**。Codex override 后的关键推理原文:

> 之前 `.ai/logs/archived/bug-20260519-h5coat-qt5core-missing/...` 里曾记录:
> - `recardbin/runtimes/qt-5.15.2/bin/` 下没有 `qt.conf`。
> - 该点当时只是嫌疑, 未被验证。

也就是说: 答案一直躺在 `.ai/logs/archived/` 里, 但 5 轮诊断没人去翻。Codex 是在 Human 喊「你自己干吧」override 后才主动想起这条归档, 立刻做 A/B 验证, 一轮解决。

## 影响

- **已知答案被埋**: 同组件 (H5Coat / Qt runtime) 上一个 epic 已经识别出嫌疑点, 本 epic 没检索归档, 重走 5 轮昂贵的 Windows VM 矩阵诊断
- **诊断成本不对称**: 修复极小 (写一个 qt.conf), 但因为没先穷尽「历史已知嫌疑」, 花了 5 轮 instrumentation (env-gated diag / PE offset mapping / WER LocalDumps 等)
- **生产环境严重**: derived 项目跨 epic 累积归档越多, 「答案在归档里但没人翻」的概率越高; 没有 Claude / 资深 Human 实时盯, 这个浪费会反复发生
- **F01-v0.5 (Assumptions to verify 段) 覆盖不全**: v0.5 让 02-plan 列假设, 但没规定「假设的来源」必须包含历史归档的未验证嫌疑

## 根因

### Gap 1: `01-codex-intake.md > Step 1.5 Evidence ingestion` 没有「同组件历史归档检索」子步

当前 Step 1.5 只摄入 Human 提供的 evidence (日志 / 截图等), 没要求 Codex 主动 `grep` 同组件的历史 epic 归档。

### Gap 2: `02-codex-plan.md > Assumptions to verify` 没规定假设来源含历史嫌疑

v0.5 F01-v0.5 加的 Assumptions 段只列「本次推理出的假设」, 没强约束「先把同组件历史归档里的未验证嫌疑 / open follow-up 列为头号候选假设」。

### Gap 3: `09-codex-closeout.md` 归档时「未验证嫌疑」没单独成段

本次能 grep 到, 是因为上个 epic 恰好在某文件里写了这句话。但 closeout 契约没强约束「未验证嫌疑 / 残留 follow-up」单独成可检索段 (e.g. 归档 `## 未验证嫌疑` 段 / task 文件固定字段), 下次 grep 命中率靠运气。

## 证据

- smart-uite `bug-20260519-h5coat-white-screen-network-path` conversation 归档第 9 段「Human override: Codex 直接接手」: Codex 推理明确引用 `bug-20260519-h5coat-qt5core-missing` 归档里「qt.conf 嫌疑未验证」
- 该 epic R1-R5 五轮诊断 matrix, 每轮 Windows VM 跑一次, 期间 R1 因 INI section 写错被 03c REJECT 一次, R5 PE parser 因只解析 1 section 被 03c REJECT 一次

## 提议修复

### 1. `01-codex-intake.md > Step 1.5` 加「同组件历史归档检索」子步

```markdown
### Step 1.5b · 同组件历史归档检索 (v0.6 · F03-v0.6)

从一句话需求 / evidence 提取核心组件名 / 模块名 / 关键文件名, 对历史归档做检索:

\`\`\`bash
grep -rl "<组件名>" .ai/logs/archived/ 2>/dev/null
\`\`\`

命中的历史 epic, 读其归档的「未验证嫌疑 / 残留 follow-up / Known Sharp Edge」段。
把命中的未验证嫌疑写入 task 文件 `## 历史关联嫌疑` 段, 移交 02-plan 作为头号候选假设。
无命中 → task 文件该段写「无历史关联」。
```

### 2. `02-codex-plan.md > Assumptions to verify` 加「历史嫌疑优先」硬约束

```markdown
- Assumptions to verify 段的**第一批假设**, 必须来自 task 文件 `## 历史关联嫌疑` 段
  (01-intake 检索到的同组件历史未验证嫌疑)。
- 若历史嫌疑可用极小 A/B (写一个文件 / 改一个配置 / 跑一条命令) 验证,
  必须在 Quick workaround 段优先排该 A/B, 早于昂贵的 instrumentation 矩阵。
```

### 3. `09-codex-closeout.md` 归档强约束「未验证嫌疑」单独成段

```markdown
归档 conversation / task 文件必须含固定段 `## 未验证嫌疑 / 残留 follow-up`
(无则写「无」), 保证后续 epic `grep` 可稳定命中。
```

## SemVer 影响

**MINOR** (01-intake 新增检索子步 + 02-plan Assumptions 来源约束 + 09-closeout 归档段强约束 · 不破坏 v0.5 旧 epic · 旧 task 文件无新段仍合法但不达 v0.6 best practice)。

## 关联

- 与 **F01-v0.5 (Assumptions to verify 段)** 直接协同: F01-v0.5 建段, F03-v0.6 规定段的来源必须含历史嫌疑
- 与 **F04-v0.6 (诊断轮次上限)** 协同: F03 让早期就翻历史 (减少轮数), F04 给轮数兜底上限
- 跨 epic 历史: smart-uite 已积累 daemon-singleton / business-manager / h5coat-start-fails / qt5core-missing / dcbusinessmanager-error2 等多个归档, 跨 epic「答案在归档里」概率随时间上升

## 实施记录 (v0.6.0-lite-rc1)

- `01-codex-intake.md`: 新增 `### Step 1.5b 同组件历史归档检索` (grep `.ai/logs/archived/` → brief `## 历史关联嫌疑` 段); brief 通用模板 + bug 模板各加 `## 历史关联嫌疑` 固定段。
- `02-codex-plan.md > §8`: 新增 `#### 8.1 历史关联嫌疑优先` — Assumptions 第一批假设必须来自 `## 历史关联嫌疑` 段; 旧 brief 无该段时 02 自补检索; 极小 A/B 优先于 instrumentation 矩阵。
- `09-codex-closeout.md`: 新增 `#### 3d 未验证嫌疑归档单独成段` — 写固定文件 `.ai/logs/archived/<epic-id>/unverified-suspicions.md` (固定 `# 未验证嫌疑` 标题); Step 4 加第 7 项 verify。
- commit: v0.6.0-lite-rc1 release commit (见 CHANGELOG)。
