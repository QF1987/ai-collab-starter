---
finding-id: lite-v0.1-finding-04-l2-dual-path
severity: P2
category: doc + prompt
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/workflow.md (§8 共享文件协议段)
  - .ai/prompts/02-codex-plan.md (§7 OC delegation candidates 段)
  - .ai/getting-started.md (§三 bug 流速记 加 L2 摸排子段)
status: implemented-in-v0.2.0-lite-rc1
related: [03]
---

# Finding 04: L2 摸排"双路并行" (OC-helper 文本 + GitNexus 符号) 没文档化

## 现象
本次 smart-uite Daemon 单例 bug 修复时, 我在 Step 2 T1 Codex 02 提示词里即兴加了 "**L2 摸排两路并行**":
- 2a: OC-helper 跑文本级 grep (Win32 keyword / lock / pid 等), 写 req-daemon-singleton-1.md
- 2b: Codex 自跑 GitNexus 符号级查询 (入口符号 / impact / api_impact), 写 gitnexus-daemon-singleton-1.md

两路结果在不同 scratch 文件, Codex finalize 02 brief 时双源汇总。

这套双路并行模式跑得非常好 (GitNexus 给出符号级精准定位, OC-helper 给出文本上下文 + 复现路径线索), 但 lite 现有文档**0 处提到这种模式**。

## 影响
- 不知道双路并行的下游 Agent 只会用单路 (要么纯 OC-helper, 要么纯 GitNexus), 错过双源验证
- 单路 false positive / false negative 风险高, 影响 02 Decision 质量
- bug 复现路径未确认场景下, 双路是最快的"建立证据基础"路径

## 根因
- `workflow.md §8 共享文件协议` 只讲 OC-helper req/out, 没讲 GitNexus 并行
- `02-codex-plan.md §7 OC delegation candidates` 段只列 OC-helper 任务, 没列 GitNexus 查询计划
- 没有 "L2 摸排" 这个概念的显式定义 (本对话中我命名为 L2, 区分 L1 Bootstrap 项目地图 vs L2 per-task 摸排)

## 证据
- 本对话 Step 2 T1 Codex 提示词 "操作步骤 2a/2b" 段, 我即兴加的双路设计
- Codex 02 跑出的 req-* (~80 行) + gitnexus-* (~367 行) 双源在 finalize 阶段汇总
- GitNexus 发现 "无 Win32 mutex 符号" + OC-helper grep 验证 "无 CreateMutex 字面命中" → 双源互证, 极高信心拒绝 hypothesis 1

## 提议修复
1. **`workflow.md` §8 共享文件协议段** 加新子段 §8.6 "L2 摸排双路并行模式":
   ```
   适用: bug 复现路径未确认 / 嫌疑符号跨子项目 / 项目 ≥ 50 KLOC
   双路:
   - 文本级 (OC-helper): 走 .ai/scratch/oc-helper/req-<bug>-N.md → out-<bug>-N.md
   - 符号级 (Codex 自跑 GitNexus): 走 .ai/scratch/oc-helper/gitnexus-<bug>-N.md
   汇总: Codex 02 finalize brief 时双源对比, 互证发现的强化 Decision, 互斥的标 follow-up
   ```
2. **`02-codex-plan.md` §7 OC delegation candidates** 段重写为两类:
   ```
   ### OC-helper 任务 (文本级)
   - 全仓 grep 错误码 / 关键 keyword
   - scan 嫌疑模块文件清单
   - summarize 长文档

   ### GitNexus 符号级查询 (Codex 自跑, MCP 工具)
   - mcp__gitnexus__query: 入口符号定位
   - mcp__gitnexus__impact: call chain / 影响面
   - mcp__gitnexus__api_impact: 跨 repo export 影响
   - mcp__gitnexus__cypher: 自定义符号 / 关系查询 (fallback)

   两类可并行, 写不同 scratch 文件, finalize 时汇总。
   ```
3. **`getting-started.md` §三 bug 流速记** 加 "Step 2 L2 摸排" 子段, 显式分 L1 (Bootstrap 项目地图) vs L2 (per-bug 摸排)

## SemVer 影响
**MINOR** (新增能力 · 双路 L2 模式)。

---

## v0.2.0-lite-rc1 实施记录 (2026-05-18)

- **release**: v0.2.0-lite-rc1
- **触发来源**: smart-uite epic (Daemon 单例 bug, commit 9afc2f7) 实战 dogfood 反馈 — lite v0.1 首次真实大型项目接入
- **实施摘要**: 见 `CHANGELOG.md > [v0.2.0-lite-rc1]` 段, 本 finding (F04) 落入对应分组 (group A/B/C/D/E/F/G), 详见 CHANGELOG `### Why these changes` 段
- **关联 commit**: 见 `git log --oneline v0.1.0-lite-rc1..v0.2.0-lite-rc1` (release 提交 hash 由 Step 6 tag 后填入)
- **archive 路径**: `.ai/logs/archived/v0.2-released/lite-v0.1-finding-04-l2-dual-path.md`
