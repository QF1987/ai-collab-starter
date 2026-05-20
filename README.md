# ai-collab-starter-lite

> **2 Agent + 1 Human 协同骨架**(Lead 脑力 + worker 体力 + Human bus)。
> `ai-collab-starter` 的独立产品线 — 适配无 Claude / air-gapped / 小团队场景。
>
> **当前状态**: v0.1.0 · 从 main v4.0-rc1 fork(2026-05-16)。**无 ACP 协议、无 MCP server,文件即真相,Human 当触发器**。

---

## lite vs main · 决策矩阵

| 你的情况 | 用哪个 |
|---------|-------|
| 有 Claude API 预算 + Opus 配额充足 + 需要架构 LLM 把关 | **main** |
| 没 Claude API / 配额受限 | **lite** |
| 隐私敏感, 需 air-gapped(local 模型) | **lite** |
| 个人 / 小团队 side project, Opus 级架构是 overkill | **lite** |
| 想探索 "Lead 架构 + worker 体力" 范式 | **lite** |
| 大团队 + 严合规审计 + 已建立 Claude 工作流 | **main** |
| 想跑 Tiny / Small 任务(< 1h) | 两边都不用,直接单 Agent 单轮 |

详细对比见 `.ai/lite-v0.1.0-design.md > §2`。

## lite 是什么

| 属性 | 值 |
|------|-----|
| Agent 数 | 4 (Lead × 1 + worker × 3 角色) + 1 Human |
| 终端数 (per epic) | 4 (T1 Lead / T2 Helper / T3 Impl / T4 Reviewer) |
| 通信协议 | **无**。Human 当 message bus + `.ai/scratch/oc-helper/` 文件总线 |
| 写代码方 | Impl(03b) |
| 拆任务 / 验收 | Lead(03a / 03c) |
| 审 | Reviewer(04,与 Impl 强制不同 session) |
| Escalation 接收方 | Human |
| 重试上限 (03b ↔ 03c) | 3 轮,超限升 Human |
| 验收 rubric | `.ai/oc-code-quality-rubric.md`(8 维度 + 5 硬门槛,门槛 ≥ 16/24) |

## 何时用 / 何时不用

### ✅ 适用场景

- 中-大型工作量 (≥ 2 小时)
- 多模块、长周期
- 跨语言 / 跨平台 / 跨仓
- 需要审计追溯
- **无 Claude 预算 + 想保留多 Agent 协同的纪律**

### ❌ 不适用场景

**绝对别用**:

- < 30 行的 typo / 注释 / 命名调整 / README 改字
- 写一封邮件、博客、聊天回复
- 探索性原型 / Jupyter notebook 灵感期 / spike
- 一次性临时脚本,不需要审计
- 写完即弃的 demo

直接和**一个** Agent 单轮对话最快。**框架是加速器,不是仪式**。

### ⚠️ 灰区

- 个人 side project: 可用但 4 终端管理负担要自己衡量
- 团队首次引入: 先在一个 Medium 任务跑通流程,再扩到 epic 级
- 已有完善 main 流程: 不建议 lite 替换,可作为补充工具(无 Claude 配额时备用)

## Quick Start (4 终端)

```bash
# 1. clone & cd
git clone <lite-repo> /path/to/your-new-project
cd /path/to/your-new-project

# 2. 开 4 个独立 agent session (tmux / iTerm tab / 桌面 app chat 均可)
#    T1: Lead              (主驱动 · 架构/拆任务/验收)
#    T2: Helper            (全仓搜索, 按需启动)
#    T3: Impl              (写代码)
#    T4: Reviewer          (独立审)
#    注: 每个 Track 跑在哪个 agent app 由你自选, 角色名不绑工具

# 3. 在 T1 Lead 喂启动 prompt (见 .ai/getting-started.md §1)
```

详细 bootstrap 步骤见 [`.ai/getting-started.md`](.ai/getting-started.md) §1。

## Quick Start (单终端探索)

如果只想跑通骨架但**不想一次开 4 终端**(初次试水 / 跑一个 Tiny task):

- Lead 可在 T1 同时模拟 Impl 角色(临时授权,标 `human-override-lead-fix`)
- Reviewer 仍建议独立终端(防自审盲点)

完整 4 终端拓扑只在 ≥ Medium epic 推荐。

## 占位符约定

starter kit 中的占位符(bootstrap 时由 Lead 或脚本填充):

| 占位符 | 含义 | 示例 |
| --- | --- | --- |
| `<PROJECT_NAME>` | 项目名 | `MyApp` |
| `<COLLAB_ROOT>` | 本协同工作目录绝对路径 | `/path/to/your-project` |
| `<REPO_PATH>` | 业务仓库绝对路径(单仓) | `/path/to/repo` |
| `<REPO_X_PATH>` | 多仓时按角色命名 | `<REPO_BACKEND_PATH>` |
| `<TECH_STACK>` | 技术栈描述 | `Go + Python + TypeScript` |
| `<TBD>` | 待填字段 | 任何 |

## 维护契约(修改 lite 自身时必读)

### 单一来源原则

| 约束 | 单一来源 | 必须同步的引用方 |
| --- | --- | --- |
| Session State Discipline | `AGENTS.md` | 5 prompts 末段 + `state.md` 头注释 |
| Language Discipline | `AGENTS.md` | 5 prompts Token 策略段 |
| Commit 阻塞规则 | `AGENTS.md` | `04-review.md` |
| 状态翻转 commit hash 校验 | `AGENTS.md` Known Sharp Edges | `04-review.md` |
| 数据契约约束分级 | `02-lead-plan.md` | ADR 范例 |
| Lead 03c 验收 rubric | `.ai/oc-code-quality-rubric.md` | `03-lead-orchestrate.md` 03c 段 |
| 4 终端拓扑 | `workflow.md §0` | `getting-started.md` / `lite-v0.1.0-design.md §3.2` |
| 「下一步提示词」4 字段格式 | 5 prompts 末段(统一) | — |

### 跟 main 的双向 sync

lite 是独立产品线,**不**是 main branch。两者通过双向 finding sync 协议共享通用改进:

- **lite → main**: 每个 lite minor release 人工扫 findings,通用项 cp 到 main `pending-findings/from-lite-<project>/`
- **main → lite**: main MINOR release 后, lite owner 评估通用改进(Claude-specific 项跳过)

详见 `.ai/lite-v0.1.0-design.md > §8`。

## 来源 + 设计文档

- **fork 起点**: `ai-collab-starter` v4.0.0-rc1(2026-05-15)
- **lite v0.1.0 设计冻结**: 2026-05-16
- **设计文档**: [`.ai/lite-v0.1.0-design.md`](.ai/lite-v0.1.0-design.md)
- **v1 归档**(ACP/MCP 协议版, 已否决): [`.ai/lite-v0.1.0-design-v1-acp-archived.md`](.ai/lite-v0.1.0-design-v1-acp-archived.md)

## 相关文档

- [STRUCTURE.md](STRUCTURE.md) — 目录布局速查(继承自 main, 部分条目对 lite 不适用)
- [AGENTS.md](AGENTS.md) — 中央纪律(已 lite 化)
- [.ai/getting-started.md](.ai/getting-started.md) — 三类入口指南 + 4 终端开法
- [.ai/workflow.md](.ai/workflow.md) — 7 步法 + 4 终端拓扑
- [.ai/oc-code-quality-rubric.md](.ai/oc-code-quality-rubric.md) — Lead 03c 验收 rubric
- [.ai/lite-upgrade-protocol.md](.ai/lite-upgrade-protocol.md) — Human 主导的升级仪式
- [.ai/prompts/](.ai/prompts/) — 5 个 lite prompt 模板

## License / 版权

<TBD: 按你的偏好选 MIT / Apache-2.0 / 内部使用等>
