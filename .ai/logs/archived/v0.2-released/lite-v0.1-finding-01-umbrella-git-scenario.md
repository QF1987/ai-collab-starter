---
finding-id: lite-v0.1-finding-01-umbrella-git-scenario
severity: P1
category: doc + prompt
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/workflow.md (§8 共享文件协议段)
  - .ai/getting-started.md (§一 Step 0 + 新增 git 拓扑章节)
  - .ai/prompts/oc-helper.md (git log 子操作说明)
  - .ai/prompts/02-codex-plan.md (OC delegation candidates 段)
status: implemented-in-v0.2.0-lite-rc1
related: [09]
---

# Finding 01: umbrella git + 子 git 混合场景 lite 文档全无, 害下游撞墙

## 现象
smart-uite 是 umbrella git (顶层 .git 只追 .ai/ + AGENTS.md) + 30 个子目录各自有独立 .git 的混合结构。
Codex 02 跑 L2 摸排时, 写给 OC-helper 的 req 文件含 "git log Daemon/ 最近 30 天 commit", 但**没说要 cd 进 Daemon 子仓里跑**。直接在 umbrella git 顶层跑 `git log -- Daemon/` 会返回空 (umbrella 不追那些路径), OC-helper 会误以为"Daemon 最近 30 天无 commit"。

Human 第一次撞这个坑, 问 "smart-uite 是 umbrella git, git log 时必须 cd 进各子项目根目录这我不知道啥意思?", 我手动给 OC-helper prompt 加了一段注意事项段才解决。

## 影响
- 任何 derived 项目用 umbrella git 拓扑 (主仓 lite 元数据 + N 个独立子 repo) 都会撞这个坑
- 真实大型 C++ / 跨语言 / monorepo-of-repos 项目这种拓扑很常见
- 不修 = 每次 Codex 写 req 都要 Human 手动加提醒, 框架失败

## 根因
- `workflow.md` §0 4 终端拓扑图没说 "git 拓扑" 维度, 只画了"信息流"
- `getting-started.md` §一 bootstrap 5 步只讲单仓, 没讲 umbrella + 子 git 怎么 init / 怎么写 .gitignore (本对话即兴出过白名单 .gitignore 方案, 应固化进 getting-started)
- `oc-helper.md` 契约没说 git 操作子目录边界
- `02-codex-plan.md` §7 OC delegation candidates 段没提醒 Codex 写 git log req 时要标 cd 路径

## 证据
- 本对话历史 2026-05-17 22:52 后 Codex 02 输出 req-daemon-singleton-1.md, `## 嫌疑 commit 区间` 段写"在 Daemon/、PublicFunction/、MsgTransManager/ 各自仓内跑 git log", 但没指定 cd 命令
- 我即兴在 state.md > Next step.可粘贴 prompt 加 "注意 (smart-uite 项目特殊性 · umbrella git 结构) ... 跑 git log 时必须 cd 进对应子目录" 段救场
- smart-uite Step 0 修复时即兴出过白名单 .gitignore 方案 (`/*` + ! 白名单 .ai/ + AGENTS.md), 这套方案在 lite 文档没固化

## 提议修复
1. **`getting-started.md` §一 Step 0 之后加新段 "§一bis · git 拓扑选择"** (~50 行):
   - 单仓 (单 .git, lite 框架元数据 + 业务代码同仓): 默认场景, 沿用现有指引
   - umbrella + 子 git (顶层 lite 元数据, 子目录各自独立 git): 新增场景, 给白名单 .gitignore 模板
   - 跨仓 (lite 仓 + 业务仓物理分离, env var $COLLAB_ROOT / $REPO_*): 已有, 但补一句"跨仓时 git 操作的 cwd 是哪个仓"
2. **`workflow.md` §0 加 "git 拓扑维度"** 子段, 说明 git 操作 cwd 边界
3. **`oc-helper.md` 加 "git 子操作纪律"** 段: req 要求跑 git log/diff/blame 时, req 必须显式给 cd 路径 + 在 OC-helper 端验证 .git 存在; OC-helper 不能假设 umbrella 一定追踪子路径
4. **`02-codex-plan.md` §7 OC delegation candidates** 段加一行: 写 git log req 时, 若目标是子仓, 必须在 req 中写 cd <子仓相对路径> 前置命令

## SemVer 影响
**MINOR** (新增能力 · umbrella git 场景指导)。本 finding 单独不够 MAJOR, 因为现有单仓场景行为不变。

---

## v0.2.0-lite-rc1 实施记录 (2026-05-18)

- **release**: v0.2.0-lite-rc1
- **触发来源**: smart-uite epic (Daemon 单例 bug, commit 9afc2f7) 实战 dogfood 反馈 — lite v0.1 首次真实大型项目接入
- **实施摘要**: 见 `CHANGELOG.md > [v0.2.0-lite-rc1]` 段, 本 finding (F01) 落入对应分组 (group A/B/C/D/E/F/G), 详见 CHANGELOG `### Why these changes` 段
- **关联 commit**: 见 `git log --oneline v0.1.0-lite-rc1..v0.2.0-lite-rc1` (release 提交 hash 由 Step 6 tag 后填入)
- **archive 路径**: `.ai/logs/archived/v0.2-released/lite-v0.1-finding-01-umbrella-git-scenario.md`
