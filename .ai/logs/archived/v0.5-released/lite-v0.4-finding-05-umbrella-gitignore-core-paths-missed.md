---
finding-id: lite-v0.4-finding-05-umbrella-gitignore-core-paths-missed
severity: P2
category: prompt + doc + critical-process-gap
source-project: lite-self (v0.4.0-lite stable dogfood · smart-uite h5coat-qt5core-missing 04 review · Claude audit catch)
discovered: 2026-05-19
target:
  - .ai/prompts/04-opencode-review.md (三步法第一步 Scope 验证加 git ls-files check)
  - .ai/prompts/03-codex-orchestrate.md (03a 子任务包模板加 paths 必须 git 追踪强约束)
  - .ai/prompts/02-codex-plan.md (强约束 5 Paths 二组分加 git 追踪 verify)
  - .ai/workflow.md (umbrella whitelist .gitignore 模式风险段)
  - .ai/getting-started.md (§一bis git 拓扑选择 umbrella + 子 git 加 .gitignore 白名单陷阱)
status: implemented-in-v0.5.0-lite-rc1
related: [F01-v0.5, F03-v0.5]
priority-tag: 严重 (P0/P1 风险等级)
---

# Finding F05-v0.5: lite contract 漏检 OC-impl 改的核心 paths 在 umbrella whitelist .gitignore 下不在 git 追踪 (修了不能 deliver)

## 现象

smart-uite v0.4.0-lite stable dogfood (h5coat-qt5core-missing P0 bug 04 review, 2026-05-19 02:50):

OC-review 04 三步法 Scope 验证 verdict CLEAN, 但**漏检关键风险**: OC-impl 改的核心实施文件**完全不在 git 追踪**:
- `cmake/StageTdmRuntime.cmake` (Slice 1 核心 path · OC-impl 修改 7.8KB)
- `interim/scripts/windows_verify_h5coat_qt_runtime.ps1` (Slice 2 核心 path · OC-impl 新增 5.3KB · F10 两阶段验证脚本)

```bash
$ git ls-files cmake/StageTdmRuntime.cmake
(空)
$ git check-ignore -v cmake/StageTdmRuntime.cmake
.gitignore:7:/*	cmake/StageTdmRuntime.cmake
```

→ smart-uite umbrella `.gitignore` whitelist 模式:
```
/*
!/.gitignore
!/.ai
!/.ai/**
!/AGENTS.md
```

→ `/*` 默认排除一切顶层目录, 只白名单 `.gitignore` / `.ai/` / `AGENTS.md`. **`cmake/` + `interim/` 都不在白名单, 完全不在 umbrella git 追踪。**

**OC-review 把这归为"设计约束 不在此 finding 范围"**, 实际上**是 P0/P1 风险等价于 bug 修复严重度** — 修了等于没修, 现场重新 staging 时核心改动**完全丢失**, P0 bug 没真修复。

跨 epic 历史: 之前 3 个 epic (daemon-singleton / daemon-business-manager-not-started / h5coat-start-fails) 都没撞这条, 因为它们改的都是子 git 仓内子项目代码 (Daemon/ / DcReaderService/ / JsCoat/, 各自子 git 追踪)。本 epic 第一次改 umbrella 顶层 cmake/ + interim/ 撞出来。

Claude (外部审计者) cross-check 才发现, OC-review 三步法 Scope 验证未 catch。

## 影响

- **P0 bug 修了等于没修**: 现场没法 sync 到核心改动, 缺包问题没解决 (本 epic 截图 bug `Qt5Core.dll 找不到` 仍会复发)
- **lite v0.4 contract 在 umbrella whitelist .gitignore 模式下的根本性 gap**: 没 force 检测"OC-impl 改的核心 paths 是否在 git 追踪"
- **OC-review 04 三步法 Scope 验证不充分**: 表格 6 项 (核心 paths 匹配 / 连带 paths / 严禁动 / 文件数 1.5x / 行数 2x / 架构敏感) 漏 "git 追踪状态"
- **跨 derived 项目通用**: 任何用 umbrella whitelist .gitignore 模式 (lite getting-started §一bis 推荐的 "umbrella + 子 git" 拓扑) 的项目都可能撞

## 根因

### Gap 1: 04 Scope 验证不查 git 追踪状态

`04-opencode-review.md > 第一步 · Scope 验证` 当前表格:
- 子任务包核心 paths 是否在 子任务包许可列表
- 连带 paths
- 严禁动 paths 是否触碰
- 文件数 ≤ 1.5x
- 单文件行数 ≤ 2x / 200 行
- 架构敏感字段

**漏**: "核心 paths 是否在 git 追踪 (`git ls-files`)"

### Gap 2: 02 Paths 二组分 + 03a 子任务包模板 无 git 追踪 verify

`02-codex-plan.md > §5 Paths 二组分` 当前: 核心 + 连带, 加 F15+F16 严禁动 7 类。
`03-codex-orchestrate.md > 03a 子任务包模板` 同。

**漏**: "core paths 必须在 git 追踪, 若 paths 含 umbrella whitelist .gitignore 排除的顶层文件, Codex 02 plan 必须 escalate Human 决策 (修 .gitignore 加白名单 vs 改实现避开 umbrella 顶层)"

### Gap 3: getting-started.md / workflow.md 缺 umbrella whitelist .gitignore 风险说明

lite v0.2 加的 `getting-started.md §一bis · git 拓扑选择` 段 (F01 触发) 给了 umbrella + 子 git 拓扑的白名单 .gitignore 模板, **但没说**: 后续 epic 改 umbrella 顶层文件 (不在 .ai/ 或 AGENTS.md 范围) 时, **必须先扩展 .gitignore 白名单**, 否则改动不入 git。

## 证据

- smart-uite 2026-05-19 h5coat-qt5core-missing 04 review verdict PATCH, RV-09 P2 只要求 commit `.ai/*`, 没 catch cmake/ + interim/ 不在 git
- Claude audit 跑 `git ls-files cmake/StageTdmRuntime.cmake` 返空 + `git check-ignore` 显示被 `/*` ignore 实锤
- smart-uite `.gitignore` 注释段 **早就预想这种扩展**: "若想让 umbrella git 也追踪某些顶层文件 (如 CMakeLists.txt / 0.doc 顶层 README), 在此处加 ! 白名单: !/CMakeLists.txt / !/cmake/"; 但**未真实执行**, 上 3 个 epic 没撞
- 本次 epic 修复方案 (Claude 帮跑): 改 .gitignore 加 `!/cmake/` + `!/cmake/**` + `!/interim/` + `!/interim/**`, 然后 `git add cmake/ interim/` 一并 commit baseline + epic 修改 (umbrella commit `af321c9`)

## 提议修复

### 1. **`04-opencode-review.md > 三步法 第一步 Scope 验证`** 加 git 追踪 check

```markdown
| 检查项 | 结果 |
|--------|------|
| 子任务包核心 paths | ... |
| 连带 paths | ... |
| 严禁动 paths | ... |
| 文件数 vs 描述 (1.5x) | ... |
| 单文件行数 vs 描述 (2x/200) | ... |
| 架构敏感字段 | ... |
| **(v0.5 · F05-v0.5) 核心 paths 在 git 追踪** | `git ls-files <core_path>` 返空 → **fail, escalate Human** (umbrella whitelist .gitignore 漏覆盖) |
```

命中信号: 任一核心 path `git ls-files` 返空 OR `git check-ignore -v` 命中 .gitignore 规则 → 升 Human 决策 (改 .gitignore 加 ! 白名单 vs 改 02 Decision 避开 umbrella 顶层)。

### 2. **`02-codex-plan.md > 强约束 5`** 加 paths 必须 git 追踪 verify

Codex 02 写 paths 二组分时, **必须显式 verify 每条 core path 在 git 追踪** (跑 `git ls-files <core_path>` 验证)。若不在, 必须:
- 在 brief "Cross-check confirmed" 段 (F01-v0.5) 显式 flag: "core path X 在 umbrella whitelist .gitignore 排除, 需 Human 决策"
- 或者 02 Decision 重选避开 umbrella 顶层文件

### 3. **`03-codex-orchestrate.md > 03a 子任务包模板`** "上下文" 段加 paths 追踪状态

```markdown
## 上下文
- task brief: ...
- pre-decisions 摘要: ...
- 本子任务涉及的 paths (核心):
  - file1 · git 追踪状态: tracked / **gitignored (需 .gitignore 白名单 扩展)**
  - file2 · git 追踪状态: tracked
- ...
```

OC-impl 03b 实施时一眼看到风险。

### 4. **`getting-started.md > §一bis · git 拓扑选择`** 补 umbrella whitelist 陷阱说明

```markdown
### umbrella + 子 git (大型多子项目)

#### 白名单 .gitignore 模板 (v0.2 F01 加)
[现有内容]

#### ⚠️ 后续扩展陷阱 (v0.5 · F05-v0.5)

后续 epic 改 umbrella 顶层文件 (e.g. cmake/CMakeLists.txt / scripts/build.sh / Dockerfile) 时, **必须先扩展 .gitignore 白名单** (加 `!/cmake/` + `!/scripts/` 等), 否则 OC-impl 改动不入 git, 修了不能 deliver。

Codex 02 plan 时**必须 verify** core paths `git ls-files` 不为空; OC-review 04 Scope 验证表加 `git ls-files <core_path>` 检测。
```

### 5. **`workflow.md > §0 git 拓扑维度`** 同步加 umbrella whitelist 风险段

## SemVer 影响

**MINOR** (新增 04 Scope 验证子项 + 02/03a paths 追踪 verify + getting-started/workflow 陷阱说明 + 跨 prompt 协同 · 不破坏 v0.4 旧 brief / 子任务包 · 旧 brief 没 verify 仍合法, 只是不达 v0.5 best practice; OC-impl 改 .gitignored 核心 path 仍能进 03b 但 04 应 escalate)。

## 关联

- 与 **F01** (umbrella git 拓扑指导, v0.2 加) 同根 — F01 引入了 umbrella whitelist .gitignore 模板, F05-v0.5 补上后续扩展陷阱
- 与 **F01-v0.5** (Codex 02 加 Assumptions to verify) 协同 — paths 追踪状态可作为 Assumptions 一类
- 与 **F09** (rubric H2 多 git paths 验证 v0.2) 协同 — H2 验证 paths 在哪个 git 仓, F05-v0.5 验证 paths 在不在 git
- **lite-self 形态**: 都是 lite framework 自演化, 通过 dogfood 跑出 contract gap

---

## v0.5.0-lite-rc1 实施记录 (2026-05-19)

- **release**: v0.5.0-lite-rc1
- **触发来源**: smart-uite v0.3/v0.4 dogfood 跨 3 epic 累积 (dcbusinessmanager-h5coat-start-fails / dcbusinessmanager-h5coat-qt5core-missing / + Claude audit)
- **实施摘要**: 详见 `CHANGELOG.md > [v0.5.0-lite-rc1]` Added/Changed 段, 本 finding (F05-v0.5) 落入对应分组
- **archive 路径**: `.ai/logs/archived/v0.5-released/lite-v0.4-finding-05-umbrella-gitignore-core-paths-missed.md`
