# GitNexus Integration (lite v0.2.0-lite · 可选接入指南 · F03)

> **作用**: lite v0.2.0 把 GitNexus 升为一等公民可选接入项。本文是接入手册 + 实战使用模式。
> **状态**: 可选 · 不接的项目沿用 v0.1 纯文本级 OC-helper 路径, 行为不变。

## 何时该接 GitNexus

满足下列任一条件即建议接入:

- 项目 ≥ 50 KLOC
- 多语言混合 (e.g. Java + TypeScript / C++ + Python)
- 跨 ≥ 5 子项目 / 模块 (e.g. smart-uite 30 子项目)
- 含复杂 call chain (IPC / RPC / event-driven / cross-thread)

不接的代价:
- 02 L2 摸排退化为单路 (纯文本级 OC-helper)
- 跨调用链追踪困难, false positive 高
- 大型项目 02 决策可能撞墙

## 接入步骤

### 1. 单仓项目

```bash
# 在项目根
npx gitnexus analyze .
# 等索引完成 (大项目 5-15 min)

# 验证
npx gitnexus status
# 应输出: indexed N symbols across M files
```

### 2. 多仓项目 (umbrella + 子 git)

通过 MCP tool `mcp__gitnexus__group_sync`, 在 Codex / Claude session 中:

```
mcp__gitnexus__group_sync(group_name="smart-uite")
```

GitNexus 自动扫 umbrella + 所有子 git, 建立跨仓符号索引。

### 3. 接入验证 (5 条试探 query)

接入后立即跑下列试探:

```
# 找最常用 export 符号
mcp__gitnexus__query(symbol="main")
mcp__gitnexus__query(symbol="init")

# 跨子项目 caller
mcp__gitnexus__impact(symbol="<某公共 header 定义的类>")

# 入口 + call chain
mcp__gitnexus__api_impact(repo="<repo>", api="<export-name>")
```

5 条全跑通 + 返回符合预期 → 接入成功, 进 §使用模式。
任一报错 → 检查 GitNexus 服务状态 / MCP 配置 / 索引完整性。

## 使用模式

### 模式 1: 02 brief 符号级预检 (替 grep 同包预检)

`02-codex-plan.md > §6 锁定新增符号名前必须 grep 同包预检` 在 v0.2.0 加了工具优先级:

1. **GitNexus 符号级** (首选): `mcp__gitnexus__query(symbol="<拟锁定标识符>")`
2. **OC-helper 文本级** (退化): 走 req-*.md
3. **Codex 自己** (有限范围)

### 模式 2: L2 摸排双路并行 (F04)

bug 复现路径未确认 / 嫌疑符号跨子项目时, 双路并发:

```
2a (文本级 · OC-helper):
  Codex 写 .ai/scratch/oc-helper/req-<bug>-1.md
  OC-helper 跑 grep, 写 out-<bug>-1.md

2b (符号级 · Codex 自跑 GitNexus):
  Codex 在 T1 直接调 mcp__gitnexus__query / impact
  落档 .ai/scratch/oc-helper/gitnexus-<bug>-1.md
```

Codex 02 finalize brief 时双源汇总:
- 互证发现 → 强化 Decision
- 互斥结果 → 标 follow-up, Codex 自己读最小源码片段定夺

### 模式 3: 影响面分析 (Codex 03a 拆任务前)

03a 拆任务时, Codex 跑 `mcp__gitnexus__impact(symbol="<拟改函数>")` 看影响面, 决定:
- 是否需要拆多 slice
- 是否需要扩 paths (核心组 / 连带组)
- 是否需要在严禁动列表加更多 paths (F16 高风险类别 checklist)

### 模式 4: 跨 repo export 影响 (Codex 02 决策 API breaking change)

涉及修改公共 export 时:
```
mcp__gitnexus__api_impact(repo="<source-repo>", api="<api-name>")
```
返回所有引用的下游 repo + 文件 + 行号, Codex 决策是否破坏向后兼容 / 是否需要 N 个版本 deprecation。

## 与 OC-helper 的关系

| 维度 | GitNexus | OC-helper |
|-----|----------|-----------|
| 查询粒度 | 符号级 (函数 / 类 / 字段) | 文本级 (字符串 / 正则) |
| 精度 | 高 (无 false positive) | 中 (有 false positive, F11 默认过滤第三方降噪) |
| 适用 | 已索引项目 | 任何项目 (无依赖) |
| 跨语言 | 是 (索引器支持) | 是 (但语义层面割裂) |
| 跨 repo | 是 (group_sync) | 否 (单 repo 内) |
| 延迟 | 即时 (索引后) | 实时 (但慢) |
| 适合场景 | call chain / 影响面 / 符号唯一性 | 字面值匹配 / 配置查找 / 错误码定位 |

**lite v0.2.0 默认推荐**: GitNexus + OC-helper 双路并行 (L2 摸排), 见 workflow.md §8.6。

## 不接 GitNexus 怎么办

完全可选。不接时:
- 02 §6 工具优先级退化为 OC-helper + Codex 有限范围
- L2 摸排走单路 (纯 OC-helper)
- 工作流其它全部行为不变

不接的项目**不要**在 02 brief / 03a 子任务包中引用 GitNexus 工具调用。

## 维护与更新

- GitNexus 索引会随代码变化 stale: 大改动 / 重命名后跑 `mcp__gitnexus__group_sync` 或 `mcp__gitnexus__detect_changes` 增量更新
- 索引清理: `npx gitnexus clean` 后重新 analyze
- 详细使用见 GitNexus 官方文档 / 项目内 README

## 关联文档

- `.ai/workflow.md > §8.6 L2 摸排双路并行模式` — 双路并发协议
- `.ai/prompts/02-codex-plan.md > §6` — 工具优先级
- `.ai/prompts/02-codex-plan.md > §7 OC delegation candidates` — GitNexus 任务清单格式
- `.ai/getting-started.md > §一 Step 4.5` — Bootstrap 接入步骤
- `.ai/prompts/oc-helper.md > F11 默认过滤` — OC-helper 端配合
