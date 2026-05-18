---
finding-id: lite-v0.4-finding-02-oc-helper-default-exclude-ai-scratch
severity: P3
category: prompt
source-project: lite-self (v0.4.0-lite-rc1 dogfood · smart-uite dcbusinessmanager-h5coat-start-fails bug 02 L2 摸排 OC-helper out)
discovered: 2026-05-18
target:
  - .ai/prompts/oc-helper.md (grep 任务默认 --exclude-dir 清单加 .ai/scratch)
status: pending
related: [F11, F01-v0.5]
---

# Finding F02-v0.5: OC-helper grep 默认 `--exclude-dir` 漏 `.ai/scratch`, 导致 OC-helper 自指 scratch 自己的 req/out/gitnexus 文件

## 现象

smart-uite v0.4.0-lite-rc1 dogfood (dcbusinessmanager-h5coat-start-fails P0 bug 02 L2 摸排 阶段, 2026-05-18):

Codex 02 写 OC-helper req `req-bug-20260518-dcbusinessmanager-h5coat-start-fails-1.md`:
- pattern: `StartH5Bit|Type32Bit|bin_64bit|H5Coat\.exe启动出错|启动H5外壳|启动 H5 外壳|signal_showH5Coat|slot_ShowH5coat|H5ActivateOrLaunch`
- additional_exclude_dirs: `["recardbin", "interim", ".ai/archive", ".ai/logs"]`
- max_matches: 200

OC-helper out 文件 (`out-bug-20260518-dcbusinessmanager-h5coat-start-fails-1.md`) 66 个 match, 但其中:

- `.ai/scratch/oc-helper/gitnexus-bug-20260518-dcbusinessmanager-h5coat-start-fails-1.md` (**10 matches**) — OC-helper grep 命中了 **Codex 自跑 GitNexus 落档的同一 epic scratch 文件**
- `.ai/scratch/oc-helper/req-bug-20260518-dcbusinessmanager-h5coat-start-fails-1.md` (**4 matches**) — OC-helper grep 命中了**自己的 req 文件** (pattern 引用了 req 里同样的 keyword)
- `.ai/state.md` (**2 matches**)
- `.ai/tasks/bug-20260518-dcbusinessmanager-h5coat-start-fails.md` (**10 matches**) — brief 文件含 keyword 引用

**~26 个 match 是 lite framework 元数据自指 noise**, 不是业务代码。占 66 总命中的 ~40%。

## 影响

- **配额浪费**: max_matches: 200 范围内, ~40% 被 framework noise 占, 真实业务命中只剩 ~60%
- **Pattern A Human 接力困惑**: Human 看 out 文件时, 一堆 `.ai/scratch/oc-helper/gitnexus-*.md:N | ...` 引用看着像是 framework bug, 实际是自指 noise
- **Codex 02 finalize 偶尔 grep noise 干扰**: 虽然能识别 (人眼看明显), 但 Codex 不一定每次都能区分 noise vs business signal, 自动化 LLM 分析风险更高
- **递归自指潜在风险**: 若 Codex 02 写更多 scratch 文件 / 同 epic 多轮 L2 跑出更多 scratch 文件, noise 会指数增长

## 根因

`oc-helper.md > grep 任务` 默认 `--exclude-dir` 清单 (v0.2.0 · F11):
```
--exclude-dir=.git
--exclude-dir=node_modules
--exclude-dir=vendor
--exclude-dir=3rdLibraries
--exclude-dir=third_party
--exclude-dir=external
--exclude-dir=boost
--exclude-dir=Boost
--exclude-dir=.venv
--exclude-dir=venv
--exclude-dir=__pycache__
--exclude-dir=build
--exclude-dir=Release
--exclude-dir=Debug
--exclude-dir=dist
--exclude-dir=target
```

**漏**: `.ai/scratch` (OC-helper 自己的工作目录, 该目录下所有 req/out/gitnexus/oc-impl-package 都是 framework 元数据, 不该被自己 grep)

类似漏的还有:
- `.ai/state.md` (lite Pattern A 状态文件, 含 epic 历史 Notes 引用 keyword)
- `.ai/tasks/<*>.md` (epic brief 文件, 自然含 epic keyword)
- `.ai/progress.md` (epic 流水账)
- `.ai/decisions.md` (ADR 历史含 keyword)
- `.ai/review.md` (review finding 含 epic keyword)
- `.ai/logs/archived/` 和 `.ai/logs/rejected-*/` (已归档 finding)

虽然 Codex 在 req 里可以主动加 `additional_exclude_dirs`, 但**这是个 lite framework 通用约束** (任何项目用 OC-helper 都会撞 lite 元数据自指), 应该作为默认 exclude 不需 Codex 每次手动加。

## 证据

- smart-uite 2026-05-18 02 L2 摸排 out 文件: ~26/66 命中是 `.ai/scratch/` `.ai/state.md` `.ai/tasks/` 等 lite framework 文件
- Codex 02 req 主动加了 `additional_exclude_dirs: [".ai/archive", ".ai/logs"]` (说明 Codex 知道这是个问题, 但漏了 `.ai/scratch` `.ai/state.md` `.ai/tasks`)

## 提议修复

### 1. **`oc-helper.md > grep 任务`** 默认 `--exclude-dir` 加 `.ai/scratch`

```bash
grep -rn -C <context_lines> "<pattern>" <path> \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  --exclude-dir=vendor \
  --exclude-dir=3rdLibraries \
  --exclude-dir=third_party \
  --exclude-dir=external \
  --exclude-dir=boost \
  --exclude-dir=Boost \
  --exclude-dir=.venv \
  --exclude-dir=venv \
  --exclude-dir=__pycache__ \
  --exclude-dir=build \
  --exclude-dir=Release \
  --exclude-dir=Debug \
  --exclude-dir=dist \
  --exclude-dir=target \
  --exclude-dir=.ai/scratch \
  | head -<max_matches>
```

### 2. **`oc-helper.md > 默认过滤理由`** 段加一条

```markdown
- `.ai/scratch` (v0.5 · F02-v0.5) — OC-helper 自己的工作目录, 该目录下所有 req/out/gitnexus/oc-impl-package 都是 framework 元数据, grep 命中自指会污染配额
```

### 3. **`oc-helper.md > 例外`** 段同步更新

```markdown
**例外**: 若 req `intent` 段明确说 "包括第三方依赖" / "包括 lite framework 元数据" (e.g. 排查 framework finding 漂移 / lite 自演化分析), req `action` 加 `include_third_party: true` (移除第三方过滤) **或** `include_lite_metadata: true` (v0.5 加, 移除 .ai/scratch 过滤)。
```

### 4. **可选: 加 .ai/state.md / .ai/tasks/ / .ai/decisions.md / .ai/review.md / .ai/progress.md 进默认 exclude**

这些是 lite Pattern A 状态文件, 一般 OC-helper grep 不应命中。但 `grep --exclude-dir` 只支持目录, 不能直接排除单文件。可以:

- (a) 把所有 lite 元数据放在 `.ai/` 子目录 (除了源码引用), 默认 `--exclude-dir=.ai` — **太激进** (`.ai/scratch` 排除 OK, 但 `.ai/` 整个排除会让 OC-helper grep 不到 .ai/architecture.md / .ai/context.md, 这些有时是搜索目标)
- (b) 加 `--exclude='state.md' --exclude='progress.md' --exclude='review.md' --exclude='decisions.md'` — 单文件级 exclude, 但**文件名冲突风险** (业务代码可能也有同名文件), 不推荐
- (c) **不动**, 仅排 `.ai/scratch`, 其它 lite 元数据接受 minor noise (它们的命中数小, scratch 命中数最大)

**推荐 (c)**: 只排 `.ai/scratch`, 因为其它 lite 元数据文件 (state.md / tasks / progress / decisions / review) 命中数小 (≤ 10 条/epic, 通常 ≤ 3), 而 scratch 是配额杀手 (~26 条/epic), 性价比最高的过滤就是 `.ai/scratch`.

## SemVer 影响

**PATCH** (现有默认 exclude 清单增量 1 条 + 文档说明; 不破坏 v0.4 旧 req · 旧 req 没 include_lite_metadata 字段也合法, OC-helper 默认就排 .ai/scratch 反而更干净)。

## 关联与对照

- 与 **F11** (v0.2 OC-helper 默认过滤第三方) 同形态: F11 排第三方依赖 + 构建产物, F02-v0.5 排 lite framework 自己工作目录
- 与 **F01-v0.5** (Assumptions to verify) 弱关联: 都是 v0.4 dogfood smart-uite dcbusinessmanager-h5coat-start-fails bug 02 L2 摸排阶段触发
- v0.5 inbox 累计 2 条 (F01-v0.5 P2 + F02-v0.5 P3), 距升级阈值 (≥ 5) 还差 3 条, 或任一 P0/P1 触发紧迫升级
