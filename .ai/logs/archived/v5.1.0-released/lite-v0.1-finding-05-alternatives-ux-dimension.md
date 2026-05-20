---
finding-id: lite-v0.1-finding-05-alternatives-ux-dimension
severity: P2
category: prompt
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/prompts/02-codex-plan.md (§强约束 1 Alternatives considered)
  - .ai/oc-code-quality-rubric.md (D1 brief 完成度 + 新增 D9 候选 · 视情况)
status: implemented-in-v0.2.0-lite-rc1
related: []
---

# Finding 05: alternatives 强约束缺 UX (用户体验) 维度, Codex 易漏对比"功能等价但体验不同"的方案

## 现象
smart-uite Daemon 单例 bug 修复时, Bug Brief Expected 写 "严格拒绝第二实例", 现有代码实际是 "杀旧+唤窗" 策略 (`KillBeforeProcess()` + `FindWindow` 唤起已有窗口)。

这是**功能等价但用户体验完全不同**的两种设计:
- **A 严格单例**: 用户双击图标, 第二个进程无反应直接退出 — 用户可能困惑
- **B 杀旧唤窗**: 用户双击图标, 已存在窗口被前台唤起 — 用户体验顺滑
- **C A+B**: 第二实例 SendMessage 给第一实例唤窗, 自己退出

Brief Expected 锁了 A, 但用户真正想要的可能是 B 或 C。lite `02-codex-plan.md §强约束 1` 要求 alternatives ≥ 2 + 具体被拒理由, 但**没强调 "UX 差异是一个 trade-off 维度"**, Codex 容易只列技术等价方案 (PID 文件 vs CreateMutex), 漏掉 UX 等价方案。

## 影响
- 修了 bug 但用户体验恶化, 用户反馈 "原来双击会唤起窗口, 现在双击没反应了"
- bug 修复变成 regression, 需要二次修
- 反例累积: lite 设计上规避这种坑, 但当前 prompt 不足以 force Codex 想这一层

## 根因
`02-codex-plan.md §强约束 1` 当前文本:
```
- 至少列 2 个被拒方案 + 各自被拒理由
- 拒绝理由不能是 "X 不好"; 必须是 "X 在本场景下因 Y 不适合"(具体)
```
没列 "UX / 行为兼容性" 维度, Codex 自然倾向只列技术维度方案 (锁机制 / 协议 / 库选择)。

## 证据
- 本对话 2026-05-17 我审 GitNexus 结果时主动提醒 "Decision 段应对比 A/B/C 三选", 并写入 state.md > Notes "02 brief 撰写提醒"段
- Codex 02 brief 还未 finalize, 但若不强约束, 历史 dogfood 经验 (main 仓 v3.0 finding 系列) 显示 LLM 默认会漏 UX 维度

## 提议修复
**`02-codex-plan.md §强约束 1` 改写为**:
```
### 1. Alternatives considered 段不可少于 2 个方案 (v0.2.0 加 UX 维度)

至少列 2 个被拒方案 + 各自被拒理由。拒绝理由不能抽象 "X 不好", 必须是 "X 在本场景下因 Y 不适合"。

#### 必须覆盖的对比维度 (任一不满足 → alternatives 不充分)

- **技术等价**: 至少一组功能相同但实现不同的方案 (e.g. PID 文件 vs CreateMutex vs Windows Service SCM)
- **UX / 行为等价**: 至少一组用户层面感知不同的方案 (e.g. 严格拒绝第二实例 vs 唤起已存在实例 vs 静默退出 vs 弹窗提示)
- (bug 任务专属) 修复策略: minimal patch vs refactor-with-fix vs defer + workaround (本就是 §三 差异 2 要求)

#### 反例 (dogfood 留底)
❌ Daemon 单例 bug: Codex 只列 PID vs CreateMutex (技术维度), 漏 "严格单例 vs 杀旧唤窗" (UX 维度), 导致修完用户反馈"双击不再唤窗"
```

## SemVer 影响
**MINOR** (扩展现有强约束, 不破坏旧 brief 兼容性 · 旧 brief 不显式列 UX 维度仍合法, 只是新 brief 必须含)。

---

## v0.2.0-lite-rc1 实施记录 (2026-05-18)

- **release**: v0.2.0-lite-rc1
- **触发来源**: smart-uite epic (Daemon 单例 bug, commit 9afc2f7) 实战 dogfood 反馈 — lite v0.1 首次真实大型项目接入
- **实施摘要**: 见 `CHANGELOG.md > [v0.2.0-lite-rc1]` 段, 本 finding (F05) 落入对应分组 (group A/B/C/D/E/F/G), 详见 CHANGELOG `### Why these changes` 段
- **关联 commit**: 见 `git log --oneline v0.1.0-lite-rc1..v0.2.0-lite-rc1` (release 提交 hash 由 Step 6 tag 后填入)
- **archive 路径**: `.ai/logs/archived/v0.2-released/lite-v0.1-finding-05-alternatives-ux-dimension.md`

---

## main v5.1.0-rc1 处置 (2026-05-20)

**采纳** — 已翻译实施到 main 契约。详见 main `CHANGELOG.md` `[v5.1.0-rc1]` 段。
