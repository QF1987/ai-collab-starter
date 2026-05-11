# AI Collaboration Starter Kit

> 多 Agent（OpenCode + Claude Code + Codex）协同研发的项目骨架。
> 把任务从「人脑里」搬到「文件系统里」，让 session 中断、Agent 切换、月底回顾都能续上。
>
> **当前状态**：v0.1 · 从 DeviceOps 项目 dogfood 抽取（详见 §「来源 + Phase 状态」）。**未在异构项目验证**——v1.0 需要在第二个反差大的项目实战通过。

## 这是什么

一个最小可工作的目录骨架，包含：

- **8 个 prompt 模板**（`.ai/prompts/01-08-*.md`）——OC / Claude / Codex 各阶段使用
- **Intake skill**（`.claude/skills/intake/SKILL.md`）——`/intake` 命令把模糊需求结构化为 brief / task / ADR
- **状态文档体系**（`.ai/state.md` / `progress.md` / `decisions.md` / `review.md` / `context.md`）——覆盖 session 接力、决策追溯、review 状态
- **中央纪律**（`AGENTS.md`）——Agent 角色契约、文档卫生、Commit 阻塞规则、Language Discipline、Known Sharp Edges
- **入口指南**（`.ai/getting-started.md`）——新项目 / 新需求按规模路由 / Bug 处理
- **Bootstrap 脚本**（`scripts/init-collab.sh`）—— 一条命令复制骨架到目标项目

完整目录布局见 [STRUCTURE.md](STRUCTURE.md)。

## 何时用 / 何时不用

### ✅ 适用场景

- 中-大型工作量（≥ 2 小时）
- 多模块、多人 / 多 Agent、长周期
- 跨语言 / 跨平台 / 跨仓
- 需要审计追溯（团队回顾、外部 review、合规要求）

### ❌ 不适用场景

**绝对别用**：

- < 30 行的 typo / 注释 / 命名调整 / README 改字
- 写一封邮件、博客、聊天回复
- 探索性原型 / Jupyter notebook 灵感期 / spike
- 一次性临时脚本，不需要审计
- 写完即弃的 demo

这些场景直接和**一个** Agent 单轮对话最快。**框架是加速器，不是仪式**。

### ⚠️ 灰区

- 个人 side project：可用但成本/收益要自己衡量
- 团队首次引入：先在一个 Medium 任务跑通流程，再扩到 epic 级
- 已有完善流程的成熟项目：不建议强行替换，可作为补充工具

## Quick Start

### 1. 复制骨架到新项目

```bash
# 把 starter 放到你能访问的路径（例如 ~/ai-collab-starter）
STARTER=~/ai-collab-starter   # 或本目录所在位置

# 用脚本一条命令 bootstrap
$STARTER/scripts/init-collab.sh \
  --target /path/to/your-new-project \
  --name "MyProjectName"
```

或手动复制：

```bash
cp -r $STARTER/.ai        /path/to/your-new-project/
cp    $STARTER/AGENTS.md  /path/to/your-new-project/
cp -r $STARTER/scripts    /path/to/your-new-project/
cp -r $STARTER/.claude    /path/to/your-new-project/
```

### 2. 跑 Claude bootstrap session

打开 Claude Code，cd 到新项目目录。把下面 prompt 粘进去：

```
你是 Claude Code。本次任务为新项目 <PROJECT_NAME> bootstrap 协作框架。
按 .ai/getting-started.md §1 Step 4 描述的流程：
1. 读项目顶层元数据
2. 输出 .ai/context.md、.ai/architecture.md、AGENTS.md 三份草稿
3. 不要扫源码细节
4. 单次会话内完成
```

详细 bootstrap prompt 见 `.ai/getting-started.md` §1 Step 4。

### 3. 人审后开始第一个真实任务

- 把 `.ai/*.template` 改名为正式文件（`mv context.md.template context.md` 等）
- 跑 `/intake` 开你的第一个真任务

完整 5 步 bootstrap 详见 `.ai/getting-started.md` §1。

## 占位符约定

starter kit 中的占位符（bootstrap 时由 Claude 或 `init-collab.sh` 填充）：

| 占位符 | 含义 | 示例 |
| --- | --- | --- |
| `<PROJECT_NAME>` | 项目名 | `MyApp` / `DeviceOps` |
| `<COLLAB_ROOT>` | 本协同工作目录绝对路径 | `/path/to/your-project` |
| `<REPO_PATH>` | 业务仓库绝对路径（单仓） | `/path/to/repo` |
| `<REPO_X_PATH>` | 多仓时按角色命名 | `<REPO_BACKEND_PATH>` |
| `<TECH_STACK>` | 技术栈描述 | `Go + Python + TypeScript` |
| `<TBD>` | 待填字段 | 任何 |

风格：尖括号 `<X>` 用于说明文档；`$X` 保留给 AGENTS.md 中真实运行时 env var。

## 维护契约（修改 starter kit 自身时必读）

### 单一来源原则

某些约束跨多个文件，**单一来源**在 `AGENTS.md`。任何修改时**所有引用方必须同步更新**——否则 Agent 行为漂移。

| 约束 | 单一来源 | 必须同步的引用方 |
| --- | --- | --- |
| Session State Discipline | `AGENTS.md` | 8 prompts 末段 + `state.md` 头注释 + SKILL.md Step 3 |
| Language Discipline | `AGENTS.md` | 8 prompts Token 策略段 |
| Commit 阻塞规则 | `AGENTS.md` | `04-opencode-review.md` |
| 状态翻转 commit hash 校验 | `AGENTS.md` Known Sharp Edges | `04-opencode-review.md` |
| 数据契约约束分三级 | `02-claude-plan.md` | ADR 范例 |
| 「下一步提示词」4 字段格式 | 8 prompts 末段（统一） | SKILL.md Step 3 |

### 添加新 prompt 模板

如新增 `09-*.md`（如 release manager 角色等），必须：

1. 在 `STRUCTURE.md > Prompt 体系` 表中加一行
2. 在 `getting-started.md > 流程入口` 段引用
3. 在 `AGENTS.md > Agent Responsibilities` 段说明该角色

### 添加新 Known Sharp Edge

由发现的 Agent 在跑完任务后追加到目标项目的 `AGENTS.md > Known Sharp Edges`。**不要**改 starter kit 自身的 sharp edges——starter kit 只留通用例子。项目特定坑应在该项目内累积。

## 来源 + Phase 状态

本 starter kit 从 **DeviceOps 项目** dogfood 抽取（参考 DeviceOps 的 `.ai/phase2-retrospective.md`）。

### Phase 历程

| Phase | 内容 | 状态 |
| --- | --- | --- |
| Phase 1 | DeviceOps 内修最初 8 漏洞 + 中文化 + 加 intake skill | ✅ |
| Phase 2 | DeviceOps 内 dogfood（跑一个跨仓 epic）+ 暴露 6 个真实漏洞 | ✅ |
| Phase 3 Step 1 | 修这 6 漏洞 + 用户提的 3 个问题 | ✅ |
| Phase 3 Step 2 | **抽 starter kit**（本仓库） | ✅ 当前阶段 |
| Phase 3 Step 3 | 加 bootstrap 脚本 | ✅（含 `init-collab.sh`） |
| Phase 3 Step 4 | 写 README / STRUCTURE / 何时不用指南 | ✅（含本文件） |
| Phase 3 Step 5 | **在反差大的第二个项目实战验证** | ⏳ **未做** |

### 已知限制（v0.1）

1. **只在 DeviceOps 一个项目验证过**——抽取过程已主动去 DeviceOps 化，但隐藏依赖可能仍存在
2. **第二个验证项目应当反差大**——不要再选跨仓 gRPC + 多语言 enum 的项目；建议 Python 库 / 单仓 web app / 数据管道
3. **未抽工具脚本**：`gen-proto.sh` / `release-status-smoke.sh` 等是 DeviceOps 特定，未带进 starter
4. **未实测全部 prompt 模板**：8 个 prompt 中 01-04 / 07-08 在 DeviceOps dogfood 都跑过；05 / 06 实际使用频率较低，effectiveness 待验证

### 反馈渠道

跑通新项目后的 dogfood 发现，建议记录到该项目的 `progress.md`，并把可普适化的回写到本 starter kit 对应文件。

## 相关文档

- [STRUCTURE.md](STRUCTURE.md) — 目录布局速查
- [AGENTS.md](AGENTS.md) — 中央纪律
- [.ai/getting-started.md](.ai/getting-started.md) — 三类入口指南
- [.ai/workflow.md](.ai/workflow.md) — 7 步法
- [.ai/intake-templates.md](.ai/intake-templates.md) — intake 问题库
- [.ai/prompts/](.ai/prompts/) — 8 个 prompt 模板

## License / 版权

<TBD：按你的偏好选 MIT / Apache-2.0 / 内部使用等>
