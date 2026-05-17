---
finding-id: lite-v0.1-finding-03-gitnexus-first-class
severity: P2
category: doc + prompt + new-capability
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/getting-started.md (§一 Step 4 加可选 GitNexus 接入步骤 Step 0.5)
  - .ai/prompts/02-codex-plan.md (§6 锁定符号名前 grep 同包预检)
  - .ai/workflow.md (§8 共享文件协议段加 GitNexus 并行说明)
  - 新增 .ai/gitnexus-integration.md (可选接入指南)
status: pending
related: [04]
---

# Finding 03: GitNexus 不是 lite 一等公民, Bootstrap 没原生包含, 02 prompt 没把符号级查询列为首选

## 现象
本次 smart-uite 接 lite 时, Bootstrap 提示词原版无 GitNexus, 我即兴加了 "第 6 步 GitNexus 索引计划" 和单独的 "Step 0.5 GitNexus group_sync 提示词", 跑完后 GitNexus 在 02 L2 阶段给出极有价值的符号级查询 (Daemon.cpp:main 入口 / 无 mutex 符号 / KillBeforeProcess 杀旧策略 等)。

但这些都是 ad-hoc, lite 原文档 0 处提到 GitNexus, 02-codex-plan.md §6 锁定符号名前 grep 同包预检只说 "全仓走 OC-helper, 有限范围 Codex 自己", 没把 `mcp__gitnexus__query` / `impact` / `api_impact` 作为符号级首选。

## 影响
- 不接 GitNexus 的 derived 项目错过符号级查询能力, 退化为 OC-helper 文本级 grep (false positive 高 + 跨调用链跟踪困难)
- 大型项目 (smart-uite 30 子项目, 任何 ≥ 100 KLOC C++/Java 项目) 没 GitNexus 跑 02 决策会撞墙
- 接 GitNexus 的项目没标准化指引, 每次都靠 Human 即兴

## 根因
- `getting-started.md §一` 5 步 bootstrap 流默认无 GitNexus
- `02-codex-plan.md §6` 没列 GitNexus 工具优先级
- `workflow.md §8` 共享文件协议只讲 OC-helper, 没讲 GitNexus + OC-helper 双路并行
- 没有 lite 专属的 GitNexus 接入指南文件

## 证据
- 本对话 2026-05-17 19:xx 我即兴出 Bootstrap 第 6 步 + Step 0.5 GitNexus 提示词
- Codex 02 跑出的 gitnexus-daemon-singleton-1.md 367 行, 4 query + 当前源码窄读补证, 极有信息密度
- GitNexus 跨子项目 group_sync 工具支持 smart-uite 30 子 git 拓扑, 是该场景神器

## 提议修复
1. **`getting-started.md` §一 Step 4 后加 "Step 5 (可选) · GitNexus 索引接入"** (50 行):
   - 判断条件: 项目 ≥ 50 KLOC / 多语言混合 / 跨 ≥ 5 子项目 / 含复杂 call chain (IPC / RPC / event-driven)
   - 接入步骤: 单仓 `npx gitnexus analyze .` / 多仓 `mcp__gitnexus__group_sync`
   - 验证 query 5 条试探 (找最常用 export / 跨子项目 caller 等)
2. **新增 `.ai/gitnexus-integration.md`** (可选指南, ~80 行): 完整接入手册 + Bootstrap 第 6 步模板 + Step 0.5 模板 (本对话已出过, 沉淀进去)
3. **`02-codex-plan.md` §6 重写**:
   ```
   ### 6. 锁定新增符号名前必须 grep 同包预检 (v0.2.0 工具优先级)

   优先级 (从高到低):
   1. **GitNexus 符号级**: 若项目已接 GitNexus 索引, 用 mcp__gitnexus__query / cypher 查同名符号
      (符号级精准 · 无 false positive · 跨子项目)
   2. **OC-helper 文本级** (全仓 grep): 若未接 GitNexus / 项目 < 50 KLOC, 走 OC-helper
   3. **Codex 自己** (有限范围 grep): 嫌疑 ≤ 3 文件且路径已知
   ```
4. **`workflow.md` §8** 段末尾加 "L2 摸排双路并行" 子段: 文本级 grep (OC-helper) + 符号级查询 (GitNexus, Codex 自跑) 可并发, 写不同 scratch 文件 (req-* vs gitnexus-*), Codex finalize 02 brief 时双源汇总

## SemVer 影响
**MINOR** (新增能力 · GitNexus 一等公民; 不接的项目不受影响, 向后兼容)。
