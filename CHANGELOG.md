# Changelog

All notable changes to **ai-collab-starter-lite** are documented here.

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html):
- **MAJOR** version when breaking changes to the workflow contract (prompts removed/merged, file paths renamed)
- **MINOR** version when adding capabilities backwards-compatibly
- **PATCH** version when fixing typos / wording / non-structural improvements

**lite vs main**: `ai-collab-starter-lite` 是 `ai-collab-starter` 的独立产品线(SemVer 独立追踪),
fork 起点见 v0.1.0 段。

---

## [v0.3.0-lite-rc1] — 2026-05-18

> ⚠️ **Release candidate · 待 ≥ 1 个真实 epic dogfood 验证 01-intake 流后翻 stable**。
> (rc1 理由: 本 release 在 v0.2.0-lite-rc1 release 后约 30 min 内完成, 加新能力时 lite 自身未跑过完整 epic 验证)

### TL;DR

- **新能力: Codex 01-intake** — Human 一句话粗描述 → Codex 反问 ≤ 5 → 产 brief 文件 (落 `.ai/tasks/<id>.md`)
- workflow.md §1 Requirement 双入口: 入口 A (Human 自写 brief, v0.1 起原入口) + 入口 B (Codex 01-intake, v0.3 新增)
- 无 breaking change · v0.1/v0.2 旧 Human 自写 brief 入口完全保留

### 触发数据

- 来源: Human 在 v0.2 release 后立刻提问 "再有新 bug/需求, 能给 Codex 一句话, 让它反问吗?"
- 实战缺口: lite v0.2 之前需求挖掘 Owner 是 Human (workflow.md §1 + getting-started.md §二), Codex 不主动 intake; Human 一句话粗描述场景没契约化支持
- 对应 main 能力: 大致对应 main 的 `intake` 技能 (Claude 主导), lite 版换 Codex 主导, 不依赖 Claude session

### Added · 新增能力

#### 新 prompt: `.ai/prompts/01-codex-intake.md`
- Codex 主导 4 步 intake: 类型识别 (feature/bug/refactor/spike/docs/chore) → 反问 ≤ 5 (单轮一次性出, 不挤牙膏) → 产 brief 文件 → 刷 state.md
- 5 类 checklist (类型对应反问问题清单, 与 F06 severity 映射 + F07 复现未确认 + F10 bug TDD 协同)
- bug brief 模板 + feature/refactor/spike/docs/chore 通用模板
- intake Q&A 留底在 brief 末尾 (审计追溯)
- 反问硬上限 5 (Human 不会被烦) · 不许跨类型反问 · 不许越界做 02 决策

#### `workflow.md §1 Requirement 双入口`
- 入口 A: Human 自写 brief (v0.1 起, 保留)
- 入口 B: Codex 01-intake (v0.3 新增)
- 两入口产出同形 brief, 下一步都是 02

#### `workflow.md §0 阶段流转图`
- 加 01-intake 起点 (可选入口)

#### `getting-started.md §二`
- 加"v0.3 新增: 一句话粗描述入口" 段 + 启动 prompt 模板
- 路由表更新: Small/Medium/Large/Epic 都标"Human 自写 brief 或 Codex 01-intake (v0.3)"

#### `state.md template`
- `当前阶段` 枚举加 `01-intake` + `01-intake-done` 两个新值

### Changed · 适配性改动

无 (新增能力 = 增量, 不改 v0.2 现有 prompt 契约)。

### Removed · 删除

无。

### Breaking changes

无 · MINOR release。v0.1/v0.2 不走 01-intake 仍合法 (入口 A 完全保留)。

### 升级指南 (derived 项目 sync v0.3)

```bash
cd <derived-project-root>

rsync -av --exclude='.git' /path/to/ai-collab-starter-lite/.ai/prompts/ .ai/prompts/   # 拿到 01-codex-intake.md
rsync -av /path/to/ai-collab-starter-lite/.ai/workflow.md .ai/
rsync -av /path/to/ai-collab-starter-lite/.ai/getting-started.md .ai/

# state.md 项目特定, surgical merge (加 01-intake / 01-intake-done 枚举)
diff .ai/state.md /path/to/ai-collab-starter-lite/.ai/state.md

# stamp version (rc 默认不强推)
echo "v0.3.0-lite-rc1  · synced $(date +%Y-%m-%d)" > .ai/STARTER_VERSION
echo "- $(date +%Y-%m-%d) · lite v0.3.0-lite-rc1 同步, 详见 ai-collab-starter-lite CHANGELOG" >> .ai/progress.md
```

### lite → main sync 候选

本能力对应 main 已有 `intake` 技能, 不需新 sync (main `intake` 是 Claude 主导, lite 01-intake 是 Codex 主导, 两边形态不同但解决同一问题)。
若 main owner 决定 sync 时机, 可参考 lite `01-codex-intake.md` 的 4 步流 + Q&A ≤ 5 上限 + 类型 checklist 设计。

---

## [v0.2.0-lite-rc1] — 2026-05-18

> ⚠️ **Release candidate · 待 ≥ 1 个独立真实 epic dogfood 验证 v0.2 强约束后翻 stable**。
> (rc1 理由: 本次升级是消化 smart-uite v0.1 反馈, 而非又跑了一轮独立的大型 epic 验证 v0.2 自身)

### TL;DR

- **16 条 finding 全消化** (1×P1 + 8×P2 + 7×P3, 来源 smart-uite 首次大型真实 dogfood)
- **新一等公民: GitNexus 符号级 L2 摸排** — 与 OC-helper 文本级并行, 大型项目 (≥ 50 KLOC / 多子项目) 神器
- **新形态指导: umbrella git + 子 git 拓扑** — 顶层 .git 只追 lite 元数据, 子目录各自独立 git (smart-uite 30 子项目 C++ 系统形态)
- **bug 任务专属强约束** — 复现路径未确认处理 / 修复策略三选 / TDD-for-bug / 两阶段证据 / Small Task Shortcut 不适用 bug
- **03a 子任务包硬约束** — 双输出 (chat + 落档 1:1) / 严禁动 paths 必列 ≥ 1 条具体 + 7 类高风险 checklist
- **rubric H2 多 git 分场景** — 单 git / umbrella + 子 git / 跨仓三场景各自的 git diff cwd
- **state.md 字段完整性** — 硬约束 + OC-review B7 兜底 + 阶段枚举扩展 (5 个过渡态)
- **02 brief 软措辞清单扩展** — 禁"或等价 / 仅当 / 若有必要 / 可考虑" 等 force trade-off 漏洞
- 无 breaking change · 旧 v0.1 brief / 子任务包 / state.md 仍合法, v0.2 是增量 best practice

### 实战数据

- **触发**: smart-uite 项目 (Windows + Linux 终端多程序 C++ 系统, umbrella git + 30 子 git 物理拓扑) 是 lite v0.1.0-rc1 首次真实大型 dogfood
- **epic**: Daemon 守护进程单例 bug 修复 (用户反馈 "守护进程启可以启动多个") — merge commit `9afc2f7`
- **跑通验证**: 02 双路 L2 (OC-helper + GitNexus) + 03 三段式 + 04 三步法全跑通; 03b 第 1 轮因 config/Daemon.ini 越界触发 H2 fail (本 release F16 高风险类别 checklist 修)
- **inbox 累积速度**: 单 epic 14 天累计 15 条 finding (远超 ≥ 5 阈值, 含 1×P1 触发"高紧迫度") + F12 跳号 (本次补落)

### Added · 新增能力

#### 新文件: `.ai/gitnexus-integration.md` (F03)
- GitNexus 一等公民可选接入手册: 何时接 / 接入步骤 / 5 条试探 query / 4 种使用模式 (符号级预检 / L2 双路 / 影响面 / 跨 repo API impact) / 与 OC-helper 对比表 / 维护更新
- 项目 ≥ 50 KLOC / 多语言 / 跨 ≥ 5 子项目 / 复杂 call chain 建议接入

#### `getting-started.md > §一bis · git 拓扑选择` (F01)
- 三种 git 拓扑显式定义: 单仓 / umbrella + 子 git / 跨仓
- umbrella + 子 git 场景白名单 .gitignore 模板 (`/*` + `!.ai/` + `!AGENTS.md`)
- 每种拓扑的 git 操作 cwd 边界约束

#### `getting-started.md > §一 Step 4.5 GitNexus 接入` (F03)
- bootstrap 阶段可选 GitNexus 接入步骤 (单仓 npx analyze / 多仓 mcp__group_sync)
- 5 条试探 query 验证接入

#### `workflow.md > §0 git 拓扑维度` (F01)
- 4 终端拓扑外加 git 拓扑维度 (单仓 / umbrella+子git / 跨仓) 三场景对照表

#### `workflow.md > §0 阶段流转图` (F13)
- ASCII 阶段流转图: 主线 6 阶段 + 5 个过渡态 (02-plan-refine / 03a-prep / 03b-retry / 04-fix-loop / <stage>-human-gate)

#### `workflow.md > §8.4 OC-impl 子任务包文件` (F14)
- 03a 子任务包必须双输出 (chat + `.ai/scratch/oc-impl-package-<task-id>-<n>.md` 落档 1:1)

#### `workflow.md > §8.6 L2 摸排双路并行模式` (F03 + F04)
- 文本级 (OC-helper) + 符号级 (GitNexus) 并行协议
- L1 (Bootstrap 项目地图) vs L2 (per-task 摸排) 显式区分

#### `02-codex-plan.md > §6 工具优先级` (F03)
- 锁定符号名前预检的三级优先级: GitNexus 符号级 > OC-helper 文本级 > Codex 自跑有限范围

#### `02-codex-plan.md > §7 OC delegation candidates` (F04 + F01 + F16)
- 拆三类: OC-helper 文本级 / GitNexus 符号级 (Codex 自跑) / OC-impl 子任务包
- 加 umbrella git 子仓 cwd 提示 (F01)
- 加 03a 严禁动候选预审 (7 类高风险 checklist · F16)

#### `02-codex-plan.md > bug 任务专属强约束` 新段 (F07)
- B-1 复现路径处理 (确认 vs 未确认双路径)
- B-2 修复策略三选 (minimal / refactor-with-fix / defer + workaround)
- B-3 bug pre-decisions 锁定 (回归测试 / 不顺手 refactor / 改动范围限定)

#### `03b-opencode-impl.md > bug 任务专属` 新段 (F10)
- TDD-for-bug: 测试先写 + pre-patch FAIL + 业务代码 + post-patch PASS
- chat 必须含 "## bug 测试两阶段证据" 段

#### `04-opencode-review.md > 3b checklist B7` (F08)
- state.md 字段完整性机器化校验 (grep 字段名 / 维护规则段 / wc -l 行数)
- 命中信号 → 升 Human

#### `oc-helper.md > git 子操作纪律` 新段 (F01)
- req 必须显式给 cd 路径 (`cwd_override` 字段)
- 执行前 verify `.git` 存在
- 禁止假设 umbrella git 追踪子路径

### Changed · 适配性改动

#### `02-codex-plan.md > §1 Alternatives considered` (F05)
- 必须覆盖 UX / 行为等价维度 (反例 Daemon 单例 bug)
- 不再只列技术等价方案

#### `02-codex-plan.md > §决策必须落到唯一具体选择` (F12)
- 禁止清单扩展: 「或等价 / 或类似」「仅当 X 时 / 仅当需要」「若有必要 / 如有需要 / 按需」「可考虑 / 可以选用」全部禁
- 加 dogfood 反例 (Daemon 单例 bug 4 条 ❌ / ✅ 对照)

#### `02-codex-plan.md / 03-codex-orchestrate.md > 收尾段` (F02)
- state.md 覆盖前必读硬约束: 禁止 condensed / 重命名字段 / 删 template 段 / 简化标题

#### `03-codex-orchestrate.md > 03a 输出哪里` (F14)
- 双输出强约束 (chat + `.ai/scratch/oc-impl-package-<task-id>-<n>.md` 落档 1:1 同步)

#### `03-codex-orchestrate.md > 子任务包模板 > 严禁动 paths` (F15 + F16)
- 必须列 ≥ 1 条具体路径 + 一句话理由
- 7 大高风险类别 checklist (构建配置 / 运行时配置 / schema / 公共 header / CI / 第三方依赖 / 其它)

#### `03b-opencode-impl.md > Scope 强约束` (F09 + F15)
- 双层验证: 分场景 git diff (单 git / umbrella + 子 git / 跨仓) + 严禁动 paths 核对

#### `04-opencode-review.md > Small Task Shortcut` (F10)
- bug 任务不适用 Small Task Shortcut

#### `04-opencode-review.md > 三步法 3a · 通用 quality` (F10)
- bug 任务专项: 检查 chat / progress.md 两阶段证据

#### `oc-helper.md > grep 任务` (F11)
- 默认 `--exclude-dir` 17 类目录 (.git / 第三方 / 构建产物)
- req `include_third_party: false` (默认) / `additional_exclude_dirs` 项目特定追加
- out notes 段必标过滤数 (若过滤 ≥ 10 条)

#### `oc-code-quality-rubric.md > H2` (F09 + F15)
- 分场景 git diff 验证 (单 git / umbrella + 子 git / 跨仓)
- 加严禁动 paths 核对

#### `oc-code-quality-rubric.md > D3 + D5` (F10 + F16)
- D3 bug 任务专项子项 (revert 验证 / 两阶段证据)
- D5 fail 信号加 config/*.ini / *.proto / migration / 公共 header

#### `state.md` template (F02 + F13 + F14)
- 头部加字段完整性硬约束段
- `Active task.当前阶段` 注释扩展 5 个过渡态枚举
- `Last completed step.产出` 加子任务包落档约定

#### `getting-started.md > §三 差异 1` (F06 + F07)
- Bug Brief 模板 Reproduction 段加未确认场景处理 + 复现要求段
- Severity → human-escalation-suggested 默认映射表

#### `getting-started.md > §三 差异 3 + 速记` (F07 + F10 + F04)
- AC 加未确认场景必须先复现验证
- AC 加 bug 两阶段证据要求
- 速记 Step 2 加 L2 双路并行 (OC-helper + GitNexus)

### Removed · 删除

无 · 全部增量改动, v0.1 旧 prompt / brief / state.md 仍合法。

### Why these changes (按 finding 编号 · 实战 case 摘要)

- **F01** (P1 · umbrella git 拓扑): smart-uite umbrella + 30 子 git, Codex 写 req 没指定 cd 子仓, OC-helper 在 umbrella 顶层跑 git log 返回空 → 误判子项目无 commit。修 4 处文档 + 1 处 prompt
- **F02** (P2 · state.md 字段漂移): Codex 02 跑完 L2 后刷 state.md 多字段被 condensed, 头部简化, 维护规则段被删 → Pattern A 跨 session 重建质量下降。修 4 处 prompt + 1 处 template
- **F03** (P2 · GitNexus 一等公民): smart-uite 接入 GitNexus 给出极有价值的符号级查询 (Daemon.cpp:main / 无 mutex 符号), 但 lite 0 文档提到, ad-hoc 接入。新增 1 文件 + 3 处 prompt 改动
- **F04** (P2 · L2 双路并行): OC-helper 文本级 + GitNexus 符号级双路并发跑得非常好, 但 lite 0 文档化。修 3 处 prompt + 1 处 doc
- **F05** (P2 · UX 维度): Daemon 单例 bug Expected 写"严格单例", 实际代码"杀旧+唤窗", 若 Codex 只列技术等价方案 (PID vs Mutex) 漏 UX 维度 → 修完用户反馈"双击不再唤窗"。修 §1 强约束 + 加 D9 候选
- **F06** (P3 · severity-escalation 映射): Bug Brief 模板 `human-escalation-suggested` 无默认值规则, 凭经验填易漂移。加映射表
- **F07** (P2 · 复现未确认纪律): Daemon bug 复现路径未确认 (4 条嫌疑), 现有 prompt 没说怎么处理。加 02 bug 专属 B-1 + getting-started Reproduction 段 + AC 项
- **F08** (P3 · B7 state 完整性): F02 的 review 兜底, 04 三步法 3b checklist 加 B7
- **F09** (P2 · H2 多 git 验证): rubric H2 `git diff --cached --stat` 在 umbrella 跑返空, OC-impl/Codex 03c 误判 scope 干净。修 rubric H2 + 03b/03c 分场景
- **F10** (P3 · bug TDD revert-verify): bug 修复回归测试有"pre-patch 必须 fail"特殊要求, 现有 prompt 没 enforce 到 03b/03c/04 流程。修 3 处 prompt + rubric D3
- **F11** (P3 · OC-helper 第三方过滤): smart-uite grep Win32 keyword 命中 200+ 条 boost 头文件, OC 自觉过滤但 prompt 未 force。加默认 --exclude-dir + req 字段 + out notes 提示
- **F12** (P3 · 软措辞清单): 02 brief 软条件等价措辞 (或等价 / 仅当 / 若有必要 / 可考虑) 漏在禁止清单外。扩展清单 + 反例
- **F13** (P3 · 阶段枚举漂移): Codex 自创 `03a-prep` / `02-plan approved · micro L2 before 03a`, 不在 template 枚举内。加 5 个过渡态枚举 + workflow.md 阶段流转图
- **F14** (P2 · 03a 子任务包落档): 子任务包正文只在 chat, 没落档 → Pattern A 跨 session 重建失败, Claude 辅助审计失败。加双输出强约束 + workflow §8.4 + state.md 产出字段约定
- **F15** (P3 · 严禁动具体路径): 03a 子任务包"严禁动 paths: 其余全部"是通用兜底, Codex 自觉补 Daemon/CMakeLists.txt 是自发行为非模板 force。模板改为必须列 ≥ 1 条具体路径
- **F16** (P2 · 高风险类别 checklist): smart-uite 03b 第 1 轮 verify fail 因 OC-impl 顺手改 Daemon/config/Daemon.ini, F15 修了"必须列"但没指导"列哪些类别"。模板加 7 大高风险类别 checklist + D5 fail 信号

### Breaking changes

无 · MINOR release。

旧 v0.1 brief / 子任务包 / state.md / OC-helper req 不显式带 v0.2 新字段仍合法, 只是不达 v0.2 best practice。新建 brief / 子任务包 / state.md 必须符合 v0.2 强约束。

### 升级指南 (derived 项目 sync v0.2)

```bash
cd <derived-project-root>

# 1. rsync prompts + key configs
rsync -av --exclude='.git' /path/to/ai-collab-starter-lite/.ai/prompts/ .ai/prompts/
rsync -av /path/to/ai-collab-starter-lite/.ai/intake-templates.md .ai/
rsync -av /path/to/ai-collab-starter-lite/.ai/workflow.md .ai/
rsync -av /path/to/ai-collab-starter-lite/.ai/oc-code-quality-rubric.md .ai/
rsync -av /path/to/ai-collab-starter-lite/.ai/gitnexus-integration.md .ai/  # v0.2.0 新增

# 2. surgical merge (项目特定文件): state.md / decisions.md / context.md 不覆盖, 手动看 diff
diff .ai/state.md /path/to/ai-collab-starter-lite/.ai/state.md   # 评估字段完整性变化
diff .ai/getting-started.md /path/to/ai-collab-starter-lite/.ai/getting-started.md

# 3. stamp version (rc 版本默认不强推 STARTER_VERSION; 若 Human 决定推则:)
echo "v0.2.0-lite-rc1  · synced $(date +%Y-%m-%d)" > .ai/STARTER_VERSION
echo "- $(date +%Y-%m-%d) · lite v0.2.0-lite-rc1 同步, 详见 ai-collab-starter-lite CHANGELOG" >> .ai/progress.md
```

**v0.1 → v0.2 不兼容场景**: 无 (MINOR), derived 项目可不 sync 继续跑 v0.1 prompts。

### lite → main sync 候选

本次实施的通用 finding (非 Claude-specific 项, 可 sync 到 main inbox):

- **F02** state.md 字段完整性 (main 同样适用 Pattern A)
- **F03** GitNexus 一等公民 (main 同样可受益, 但 main 已有 Claude session 跑符号级查询, 优先级低)
- **F05** alternatives UX 维度 (普适)
- **F06** severity-escalation 映射 (普适)
- **F07** 复现未确认纪律 (普适)
- **F09** H2 多 git 验证 (普适, main 也有多 git 场景)
- **F10** bug 任务 TDD revert-verify (普适)
- **F11** OC-helper 第三方过滤 (main 无 OC-helper, sync 改名 grep helper)
- **F12** 软措辞清单 (普适)
- **F13** 阶段枚举扩展 (普适)
- **F14** 子任务包落档 (main 也涉及, Pattern A 同样依赖)
- **F15** 严禁动具体路径 (普适)
- **F16** 高风险类别 checklist (普适)

**lite-specific (不 sync)**:
- F01 umbrella git (main 已隐式支持 git 拓扑变化, 不必复制 lite 章节)
- F04 L2 双路并行 (main 无 OC-helper, 设计前提不同)
- F08 B7 state.md 完整性 (main 04 prompt 结构不同)

---

## [v0.1.0-lite] — 2026-05-16

> **lite 产品线起点**。从 `ai-collab-starter` v4.0.0-rc1 fork,删除 Claude 角色,
> 引入 Codex 当 lead engineer + OC 写代码 + Human 当 bus 的 4 终端协同范式。
>
> ⚠️ **Release candidate · 待 ≥ 1 个真实 epic dogfood 验证后翻 stable**。

### TL;DR

- **角色重排**: Codex(02 plan + 03a 拆任务 + 03c 验收, **不写代码**) + OC-impl(03b 写代码) + OC-review(04 审) + OC-helper(全仓搜索, 按需) + Human(message bus + escalation gate)
- **拓扑**: 4 终端 per epic(T1 Codex + T2 OC-helper + T3 OC-impl + T4 OC-review)
- **协议**: **无**。Human 当 bus + `.ai/scratch/oc-helper/` 共享文件总线(req/out 文件交换)
- **rubric 化验收**: 新增 `.ai/oc-code-quality-rubric.md`(8 维度 + 5 硬门槛, ≥ 16/24 通过)
- **重试上限**: 03b ↔ 03c 最多 3 轮, 超限升 Human 三选

### 设计源流

- **fork 起点**: ai-collab-starter v4.0.0-rc1 (commit c9f25ea, 2026-05-15)
- **设计冻结**: `.ai/lite-v0.1.0-design.md` (v2 · 无协议版, 2026-05-16)
- **v1 设计 (ACP via MCP) 已否决**: 归档为 `.ai/lite-v0.1.0-design-v1-acp-archived.md`,
  否决理由: IBM BeeAI ACP 已 2025-08-27 archived 合并入 A2A; Codex CLI 不原生支持 ACP;
  HTTP REST server 与 lite 极简定位矛盾。Human 决策出局, 改用 "无协议 + Human bus + 文件总线" 设计。

### Added · 新增能力

#### 新 prompt: `.ai/prompts/02-codex-plan.md`
- 替代 main 的 `02-claude-plan.md`
- 强约束 7 条: alternatives ≥ 2 / Data Contract L1-L5 / Negative consequences 不空 /
  pre-decisions ≥ 3 (frontmatter 锁定) / Paths 二组分 / 锁名前 grep 同包预检 / OC delegation candidates
- Codex 自然倾向 force-反: 不擅长 trade-off 决策, prompt 强制 force 出来

#### 新 prompt: `.ai/prompts/03-codex-orchestrate.md`
- 替代 main 的 `03-codex-implement.md` (lite 中 Codex **不写代码**)
- 改名 orchestrate 反映 lead engineer 角色
- 含 03a 拆任务 + 03c 验收两段, 03b 单独 prompt 给 OC-impl

#### 新 prompt: `.ai/prompts/03b-opencode-impl.md`
- OC-impl 写代码强约束: 只动子任务包 paths / 不翻案 pre-decisions / 单文件 > 200 行停下来问 / 完成只说 "done, 见 git diff"
- 子任务包模板 (Codex 03a 产出 → OC-impl 03b 消费)

#### 新 prompt: `.ai/prompts/oc-helper.md`
- OC-helper 通用 prompt: 读 `.ai/scratch/oc-helper/req-*.md`, 执行 grep/scan/summarize, 写 out-*.md
- 不动业务代码, 只读全仓 + 写共享文件

#### 新 rubric: `.ai/oc-code-quality-rubric.md`
- Codex 03c 验收 OC-impl 产出的打分表
- 5 硬门槛 (H1-H5): pre-decisions / paths / 编译 / 现有测试 / 单文件 200 行
- 8 维度 (D1-D8): brief 完成度 / 可读性 / 测试质量 / 边界处理 / 不越界 / 注释克制 / 安全 / 性能
- 总分 24, 门槛 **≥ 16/24** (不分核心/glue)
- 退回模板 + 维度低分常见模式速查

#### 新协议: `.ai/scratch/oc-helper/` 共享文件总线
- Codex 写 `req-<epic-id>-<n>.md`, OC-helper 写 `out-<epic-id>-<n>.md`
- 触发边界: 全仓搜索走 OC-helper, 有限范围 Codex 自己
- `.gitignore` 加 `.ai/scratch/` (epic 结束 Human 可清空)

#### 新 upgrade protocol: `.ai/lite-upgrade-protocol.md`
- 从 main 的 `starter-upgrade-protocol.md` rename + lite 化
- Human 主导 (lite 无 Claude), Codex 辅助 grep / draft CHANGELOG
- 含 lite SemVer 决策树 + lite → main 双向 sync 协议

### Changed · 适配性改动

#### `.ai/prompts/04-opencode-review.md`
- Escalation 接收方: Claude → **Human**
- 三步法第三步新增 "Codex 自审盲点专项 checklist" (catch 拆任务粗糙 / 03c 偷工 / pre-decisions 翻案 / 推倒重来)
- Escalation 判定表保留 (C1-C7), 但 Next step.Agent 改 Human

#### `.ai/state.md` template
- 删 Claude 相关字段 / 校验规则
- 触发来源 main v4.0 4 类 (A/B/C/D) → lite 3 类 (A · pre-declared / C · OC escalation / H · 重试上限)
- 新增 "当前 epic 终端布局" 段 (4 终端各自 session 状态)
- Last completed step.Agent 枚举改 Codex | OC-helper | OC-impl | OC-review | Human

#### `.ai/workflow.md`
- §0 加 4 终端拓扑图 + session 隔离规则
- §3 架构 owner 改 Codex
- §3 实施阶段拆为 03a/03b/03c 三段式
- §4 review escalation 路径改 Human
- §5 escalation 接收方改 Human
- 新增 §6.1 OC-impl 子任务包模板 + §8 共享文件协议

#### `.ai/getting-started.md`
- §〇 新 session 启动清单中 Claude 主动提醒改为 Human 看 status report
- §一 bootstrap 5 步中 "Claude bootstrap session" 改为 "Codex bootstrap session"
- §一 加 4 终端 tmux/iTerm 开法说明 + 单终端探索模式
- §三 bug 流程速记换 Codex 02 + OC-impl + OC-review + Human

#### `AGENTS.md`
- 全文 lite 化: Codex lead + OC-impl/helper/review + Human bus
- 顶部 §0 加 "lite vs main" 对比表
- Agent Responsibilities 段 4 角色明确职责 + Codex 临时写代码例外路径
- Known Sharp Edges 加 "OC-review 与 OC-impl 共谋盲点" (lite 特有, 同模型问题)
- Session State Discipline 字段表加 "当前 epic 终端布局"

#### `README.md`
- 顶部 lite vs main 决策矩阵
- Quick Start 4 终端 + 单终端探索两版
- 删 main 的 Phase 1-3 Step 5 历程, 改 lite 设计源流
- 维护契约 5 prompts (lite 比 main 少 3 个: 01-context / 06-fix / 07-draft / 08-audit)

#### `.ai/starter-upgrade-protocol.md` → `.ai/lite-upgrade-protocol.md`
- git mv + 全文 lite 化
- 主导方 Claude → Human, 升级触发条件加 "main → lite sync" 一项

#### `.ai/lite-v0.1.0-design.md`
- 设计文档 (v2 · 无协议版) 进入 lite repo 永久保留, 不归档
- v1 ACP 版归档为 `.ai/lite-v0.1.0-design-v1-acp-archived.md`

#### `VERSION`
- v4.0.0-rc1 → **v0.1.0-lite** (SemVer 重置, lite 是独立产品线)

#### `.gitignore`
- 加 `.ai/scratch/` (OC-helper 共享文件总线临时文件)

### Removed · 删除内容

#### `.ai/prompts/02-claude-plan.md` (整文件删除)
- 替换为 `02-codex-plan.md`
- lite 中无 Claude 02-plan 角色

### Kept from main · 未改但保留

以下 main v4.0-rc1 文件保留进 lite, 但 v0.1.0 暂未做 lite 化适配 (v0.2.0 候选):

- `.ai/prompts/01-opencode-context.md` (OC 上下文摸排, lite 可用)
- `.ai/prompts/06-codex-fix.md` (lite 中改由 OC-impl 修, 此 prompt 暂保留参考)
- `.ai/prompts/07-opencode-draft.md` (lite 中 OC-impl 是主路径, 草稿模式暂不用)
- `.ai/prompts/08-codex-audit.md` (lite 中 Codex 03c 走 rubric, 此 prompt 暂保留参考)
- `.ai/intake-templates.md` (intake skill 问题库, lite 复用)
- `.ai/decisions.md` / `.ai/context.md` / `.ai/architecture.md` / `.ai/plan.md` template 与 `progress.md` / `review.md` / `token-strategy.md` (协议无关, 直接复用)

### Breaking changes vs main

lite 是独立产品线, **不**视为 main 的 breaking。但若从 main v4.0 项目 migrate 到 lite:

- 删 Claude 相关 session / prompt 引用
- 02 prompt 路径换 `02-codex-plan.md`
- 03 prompt 路径换 `03-codex-orchestrate.md` + 新增 `03b-opencode-impl.md`
- state.md `Next step.触发来源` 字段值改 (A/C/H, 删 B/D)
- task brief frontmatter `claude-review-required` 改 `human-escalation-suggested`

### 升级指南

derived 项目从 main 迁移到 lite: 暂无自动脚本, 手动 rsync `.ai/prompts/` + 改 `state.md`
+ 替换 `AGENTS.md` 顶部段。详见 §设计源流。

### v0.1.0-lite → 验证清单 (从 `.ai/lite-v0.1.0-design.md` §9)

1. [x] 4 个新/改 prompt 文件各跑通一次本机 smoke
2. [x] 02-codex-plan.md 强约束 7 条全落地
3. [x] oc-code-quality-rubric.md 文件存在, 03c prompt 引用了它
4. [x] 04-opencode-review.md "Codex 自审盲点专项检查" 段有可执行 checklist
5. [x] state.md template 触发来源 lite 3 类逻辑自洽 (无 Claude 残留)
6. [x] lite-upgrade-protocol.md 7-step Human 主导版本完整
7. [x] CHANGELOG 写明 fork from main v4.0-rc1 + breaking diffs + ACP 否决记录
8. [x] 共享文件协议 smoke (T1/T2 两终端实跑) · 2026-05-16 跑通 (req-smoke-1.md / out-smoke-1.md, 13 matches, status success)
9. [x] 完整 epic smoke (4 终端齐用, throwaway hello endpoint) · 2026-05-16 跑通 (5 关键检查 + 4 流程检查全过)
10. [x] 经验回流协议在 lite-upgrade-protocol.md 引用 (§8 双向 sync)

10/10 全过, Phase 5 Human gate 通过, 进 Phase 6 rc1 release。详见 `.ai/lite-v0.1.0-smoke-checklist.md §D`。

---

## [v4.0.0-rc1] — 2026-05-15

> ⚠️ **Release candidate · 待实战 dogfood 验证后翻 stable**

(以下为 fork 来源的 main v4.0-rc1 段, 保留供溯源)



## [v4.0.0-rc1] — 2026-05-15

> ⚠️ **Release candidate · 待实战 dogfood 验证后翻 stable**
>
> 本版本是从 v3.0 实战 + 两个 meta-design 讨论(触发机制 / 跨 session 演化)推导而来,
> **0 实战 dogfood**。derived 项目默认仍 sync v3.0.0 stable,本 rc 留作 starter 自身实验。
> 下次 epic 跑通后,若信号良好 → 翻 v4.0.0 stable;若撞坑 → 退回 v3.0.0 出 rc2。

### TL;DR

为 starter 加 **跨 session 自演化基础设施 + 多源 review 触发机制 + 升级仪式文档化**。
解决两个结构性盲点:

1. **跨 session findings 失联**:v3.0 之前 finding 散在各 derived 项目本地 `.ai/logs/`,
   starter 自己看不到。新 session 的 Claude 没法知道有多少待实施。
2. **演化纯被动**:v2.0/v3.0 升级都靠 Human 显式触发。Claude 不主动监控阈值,
   findings 容易积压被遗忘。

**无 breaking change**(v4.0 完全向后兼容 v3.0 工作流契约)。

### Added · 基础设施层

#### `ai-collab-starter/VERSION`(新)
- 单行文件存当前 release 版本(如 `v3.0.0`)
- 任意脚本 / Claude session 都可 `cat` 读取

#### `.ai/logs/pending-findings/` + `.ai/logs/archived/`(新)
- 跨项目 finding 汇聚 inbox(`from-<project-name>/` 分桶)
- 已实施 finding 按 release 归档(`v2.0-released/` / `v3.0-released/`)
- 22 历史 findings 已 backfill 进 inbox(2 deferred + 17 v2.0 + 3 v3.0)
- `.ai/logs/README.md` 解释 inbox 约定 + 双写规则

#### `scripts/starter-status.sh`(新)
- 任意项目跑,输出:starter VERSION + project STARTER_VERSION drift 检测 + inbox pending count + 升级触发评估
- 支持 P0/P1 finding 强警告

#### `scripts/sync-finding.sh`(新)
- 帮助 derived 项目把 finding 同步到 starter inbox
- 自动识别 project name(git remote / pwd basename)
- 阈值告警 ≥ 5 时提醒升级

#### `derived-project/.ai/STARTER_VERSION` stamp 约定(新)
- 每个 derived 项目 stamp 一行 `vX.Y.Z · synced YYYY-MM-DD`
- `starter-status.sh` 用此 stamp 与 starter VERSION 比对检测 drift

### Added · 机制层

#### `.ai/prompts/02-claude-plan.md`
- **Task brief frontmatter 约定**(`claude-review-required: false | auto | required`)
- **多源触发清单表**(4 类:Pre-declared / Codex self-flag / OC escalation / Auto-P0-P1)
- 何时 Claude 02-plan 应主动声明 `required` 的标准

#### `.ai/prompts/03-codex-implement.md`
- **Codex self-flag 路径**:实施期发现架构敏感时,主动在 progress.md 记 `self-flag(Codex):`,
  并刷 state.md `Next step.Agent = Claude` + `触发来源 = B`

#### `.ai/prompts/04-opencode-review.md`
- **Escalation 判定表 C1-C7**(机器化):7 条机器可判定条件 + grep / count 方法
- 与触发来源 A(预声明)/ B(self-flag)的协同规则(已声明的跳过判定表)

#### `.ai/state.md` template
- 新增 `Next step.触发来源` + `Next step.触发条件` 字段
- 校验规则注释扩展为 v4.0 4 源(A/B/C/D)+ 原 v2.0 闸门

### Added · 入口层

#### `.ai/starter-upgrade-protocol.md`(新)
- starter 升级仪式 SoT,7-step 跨 session 可复现流程
- 触发条件清单 + SemVer 决策树 + rc 模式约定
- 任何 Claude session 跑此协议都一致(不依赖具体 session 上下文)

#### `.ai/getting-started.md`
- 新 §〇 段:**任何新 Claude session 启动前的检查清单**
- 决策矩阵:何时主动提醒 Human + 何时直接进业务
- Finding 落档双写约定(本地 + sync-finding.sh)

#### `AGENTS.md`
- 新增 "Claude 主动提醒升级 starter (v4.0)" 子段
- 5 类时机 + 应说什么 + 不该主动提醒的场景

### Why v4.0 而不是 v3.1 patch

最初考虑过只发 v3.1 patch(只做基础设施),但实际 backlog 包含的不只是基础设施:
- 多源触发机制(02/03/04 prompt 改动)是 v3.0 dogfood 后两个 meta-design 讨论的产物
- 升级仪式文档化是结构性新增
- 这些**新增了 minor 级能力**,不是 typo / wording 改进

按 SemVer:**MINOR**(向后兼容的新能力)。所以 v4.0.0(用 rc1 标记未 dogfood)。

### Validation status

| 类别 | 状态 |
|------|------|
| 基础设施(VERSION / stamps / scripts / inbox) | ✅ smoke 测过 |
| 机制层 prompts 改动 | ⏳ 待下个 epic 实战 |
| 升级仪式 protocol | ⏳ 待下次 starter 升级实战 |
| 整体 cross-session 检查清单 | ⏳ 待下次新 session 实战 |

**建议下一个 epic** 启动时:
1. 跑 `bash scripts/starter-status.sh` 验证检查清单工作
2. 在新 task brief 实验 `claude-review-required` frontmatter
3. 若 Codex 实施期撞到架构问题,尝试 self-flag 路径
4. epic-closeout 后回顾 v4.0 这套机制是否真有用

实战信号良好 → tag `v4.0.0` stable;撞坑 → tag `v4.0.0-rc2` 修正后重试。

### 升级指南(rc 不强推,但 starter 自己已 stamp v4.0.0-rc1)

derived 项目**不需要**主动 sync。下次升级 v4.0 stable 时再统一 sync。
若想提前体验 rc:

```bash
rsync -av --exclude='.git' /path/to/ai-collab-starter/.ai/prompts/ .ai/prompts/
rsync -av /path/to/ai-collab-starter/.ai/{intake-templates,workflow,starter-upgrade-protocol,getting-started}.md .ai/
echo "v4.0.0-rc1  · synced $(date +%Y-%m-%d)" > .ai/STARTER_VERSION
```

---

## [v3.0.0] — 2026-05-15

### TL;DR

第二次升级,基于 starter v2.0 在 **DeviceOps**(Go backend + Kotlin Android client 多仓项目)上跑通
3 条 P1 follow-up task 的二轮 dogfood 实战,沉淀 5 条 finding 全部实施。

**无 breaking change**——v3.0 完全向后兼容 v2.0 的工作流契约;所有新增内容是**模板细化 + 约束加强**。
但有 1 条**约束新增可能违反 v2.0 当前实践**:Finding #21 要求 06-codex-fix 收尾 Next step **必须**指向 Reporter verify
而非 Human merge——v2.0 实践中有时 Codex 直接给 Human,v3.0 起这种走法只在 P3 + <10 行 fix 时允许。

### 实战数据(v2.0 dogfood 二轮)

3 条 P1 形态全跑过 + Finding 20 F-A "Small Task Shortcut" 适用边界由实战确立:

| Task | 复杂度 | Verdict | 三步法适配 |
|------|--------|---------|----------|
| P1 #1 ops-only(SQL sampling) | 等价路径完成 | reframed verified | N/A(非代码) |
| P1 #2 Small(+5/-2 行 Kotlin header) | PATCH → fix → verify | F-A 确认 over-engineered(三步法读起来像审 Epic) |
| P1 #3 small-Medium(+214 行 Go CLI + tests) | PASS 一次过 | **三步法回归正常使用** |

→ **Small Task Shortcut 适用边界**:≤30 行单文件无 ADR → 简化;30+ 行/跨决策 → 三步法正常。

### Added

#### `.ai/prompts/04-opencode-review.md`

- **Small Task Shortcut 段**(Finding #20 F-A):满足 ≤30 行 + 单文件 + 无架构敏感 + 无 ADR 条件时,
  跳过完整三步法,只做"Scope + AC + 测试证据 + 一条 grep 调用点"四步精简
- **第三步 Quality 改为 repo-自适应**(Finding #20 F-B):按改动语言/生态启用对应子项
  - Java/Kotlin + Spring:N+1 / 资源关闭 / 构造器 / lifecycle
  - Go:-race / context / Close / goroutine leak / error wrap (%w)
  - TS/JS:async/await 错误链 / null safety / 副作用清理
  - Rust / SQL / ops-shell:各有专属子项
  - 跨语言项目交集都跑,但**不**跑改动语言外的项(避免 false positive)

#### `.ai/prompts/03-codex-implement.md` + `04-opencode-review.md` + `06-codex-fix.md`

- **"下一步提示词"段 v3.0 指针版**(Finding #20 F-C):
  - prompt body 强制指针式 3 字段(`必读输入` / `Expected fix ID 或 AC 指针` / `验证命令`)
  - 显式禁止在 prompt body 内复述 task / review.md 已有内容
  - 若 prompt 仍想复述细节,改进 task / review 文件而非膨胀 prompt
  - 完成后动作硬限 ≤ 2 行

#### `.ai/prompts/06-codex-fix.md`

- **收尾纪律 · Reporter verify 必经路径**(Finding #21 强约束):
  - 06-fix 完成后 Next step **必须**指向 Reporter(OC 或 Claude),不能跳过到 Human
  - 例外:仅 P3 + <10 行 fix 可指 Human
  - P0/P1 finding 严禁跳过 Reporter verify,违反视为 RV 闭合无效

#### `.ai/prompts/02-claude-plan.md`

- **锁定新增符号名前 grep 同包预检**(Finding #22 强约束):
  - task brief 最终化前 Claude 必须对目标 package 跑同名符号 grep
  - 命中冲突 → 改名或重构(重构是独立新 task)
  - 禁止把"发现冲突"的责任推给 Codex 实施期
  - 配套 grep 命令示例(Go 函数 / 变量 / map key 三套)

### Why these 5 changes

**Finding 20 (3 子项)**:v2.0 三步法对所有规模 review 一刀切,实战发现 ≤30 行小任务过重;
F-A/B/C 三子项分别解决"规模分流 / 语言适配 / prompt 模板化"三个方向。

**Finding 21**:v2.0 workflow.md §5 关闭规则要 Reporter 翻 verified,但 06-codex-fix prompt 没强制
把 Next step 指向 Reporter。DeviceOps P1 #2 实战中 Codex 直接给 Human,虽然 P2 case 无害,
但 P0/P1 同样路径会违反硬约束。本 patch 消除制度缺口。

**Finding 22**:v2.0 task brief drafting 流程中,Claude 在锁定符号名前未做 grep 同包预检。
DeviceOps P1 #3 实战中 `uploadFile` 与 `release.go:543` 已有同名冲突,Codex 实施期才发现编译失败,
被迫改名 `uploadFileHTTPURL`。本 patch 把 grounding 校验提前到 Plan 阶段。

### Unchanged from v2.0

- 8-prompt 框架(01-08;05 在 v2.0 已删除,v3.0 不动)
- workflow.md §5 关闭规则 / Escalation 路径
- intake-templates.md(C 模式 / Q-Batch / Q8 SPI / Epic 模板等)
- decisions.md L1-L5 Data Contract 五级
- state.md 校验规则注释
- worktree 收尾协议

### 升级指南(v2.0 → v3.0)

无破坏性改动,直接拉新版即可。但**建议同步给已有项目的 .ai/**(用 rsync 或 cherry-pick 这 5 个文件):

```
.ai/prompts/02-claude-plan.md
.ai/prompts/03-codex-implement.md
.ai/prompts/04-opencode-review.md
.ai/prompts/06-codex-fix.md
```

无 schema 变更 / 无文件路径变更 / 无文件删除。CHANGELOG 与 README 自动覆盖。

### Validation

v3.0 内容尚未跑 dogfood 三轮验证。建议下一次启动新 epic / task 时优先使用 v3.0 prompts,
若发现 Small Task Shortcut 边界 / repo-自适应表 / 指针版 prompt body / Reporter verify 强约束 / brief grounding
任一条有缺口,记 starter-v4-finding-NN-*.md 候选。

---

## [v2.0.0] — 2026-05-14

### TL;DR

第一次大规模升级,基于在异构项目(Java/Spring Boot/PostgreSQL 的支付对账系统 PaymentRecon E1)
上跑完整一轮 4-Slice epic 的实战经验,沉淀 18 条 finding 并实施其中 16 条。

**Breaking change**:删除 `.ai/prompts/05-claude-review.md`(独立 step 合并入 04-review 的 escalation 路径)。
其余改动向后兼容。

### Added

- **`.ai/intake-templates.md`**
  - Q-1 新增第三种 intake 模式 `C. context.md 已就绪`(Finding #01)。检测到 context.md 包含核心字段时,Agent 主动建议跳过散文输入
  - 探索式标识纪律新增 `[agent-decision]` 前缀(Finding #03):用户授权"你定"时 Agent 拍板的字段必须显式标识 + 写决策理由
  - §A Q6.Batch 批处理域探针(Finding #05):4 子问题覆盖触发方式 / 幂等策略 / 数据量级时限 / 失败恢复
  - §A Q8 扩展性骨架探针(Finding #06):仅 Large/Epic 触发,捕获 SPI / 插件 / 适配器模式诉求
  - **Epic 产出格式重构**(Finding #04):
    - 落盘路径从 `.ai/plan.md` 追加段改为独立文件 `.ai/tasks/<epic-id>-<slug>.md`
    - 字段扩展:加 `Batch Strategy` / `Performance Target` / `Acceptance Criteria` / `Key Decisions` / `Test Strategy` / `Extensibility` / `Proposed Slices` 段
  - AC ↔ Scope.paths 强制校验(Finding #15):Epic brief 落盘前 Agent 自检 Acceptance Criteria 涉及的所有文件都在 paths 中

- **`.ai/workflow.md`**
  - §4 实现阶段强约束:03 完成后 `Next step` 必须接 `04-opencode-review`,不可跳到下一片 03(Finding #13)
  - §5 完全重写:**单 reviewer (OC) + escalation 路径**模式;删除"Claude review 独立步骤"概念(Finding #19 方案 B)
    - §5.1 OpenCode review 三步法:Scope / Architecture / Quality
    - §5.2 Escalation 路径:6 类触发条件,Claude 介入时作为 main session 协作者
    - §5.3 "内联跑了但没记录"禁止条款
  - §8 新增 Worktree convention(Finding #08 + #09):
    - §8.1 worktree 模式触发条件
    - §8.2 worktree 收尾约定(强制 rsync 回流 + state.md 警告行)
    - §8.3 `Next step` 在 worktree 中的额外纪律

- **`.ai/state.md`(template)**
  - `Next step` 段新增校验规则注释(Finding #13):自动判定 03 后必接 04
  - `Last completed step` 产出字段约定从"具体文件清单"改为"产出根目录 + (数量请 ls 实查)"(Finding #07)

- **`.ai/decisions.md`(template)**
  - 数据契约从三级扩展到五级(Finding #12):
    - L1 列语义级 / L2 表结构级 / L3 数据级(v1.0 已有)
    - **L4 实体注解级 + L5 Mapper/Repository 接口级**(Java/Kotlin + ORM 项目适用)

- **`.ai/prompts/02-claude-plan.md`**
  - "≤ 3 切片"放宽为"推荐 3-5 切片"(Finding #10),按 Web/批处理域分级建议;单片 PR diff 300-500 行
  - Compatibility 段补 L4/L5 数据契约约束(Finding #12)
  - 附带产出段补 **AC ↔ Scope.paths 校验**纪律(Finding #15)
  - 附带产出段补 **集成测试场景特别约定**(Finding #17):完整 `@SpringBootTest` 时必须预先纳入前序 Slice 可能需要 bean wiring 修复的文件

- **`.ai/prompts/03-codex-implement.md`**
  - Scope 强约束段(Finding #14):4 类越界场景的显式处理路径,例外仅限 ≤ 3 行 idiomatic 整理
  - 后端 E2E 证据要素(Finding #05 + #18 合并):fixture 映射 / HTTP 断言 / DB 断言 / Testcontainers 证据 四要素
  - 收尾段强制 `Next step` 接 04-review(Finding #13);例外仅在 task 标 `skip-review: true` 时

- **`.ai/prompts/04-opencode-review.md`**
  - Review 三步法(Finding #14):Scope 验证 → Architecture 对齐 → Quality 常规
  - Scope-deviation 处理路径:`Status: escalated` + state.md Next step 指向 Claude
  - "形式上用 ADR 工具但价值被实现吃光"类型识别(典型:cursor 一出来就 `.toList()`)
  - 引用 05-claude-review 的地方替换为 Claude escalation(无独立 prompt)

- **`.ai/prompts/06-codex-fix.md`**
  - Scope 强约束段(Finding #14):"顺手 refactor"诱惑处理路径
  - **epic-closeout 模式**(v2.0 新增):允许跨 slice 修多个 RV;OC verify 简化为"真修了 + 测试 PASS"

- **`.claude/skills/intake/SKILL.md`**
  - 第 5 步新增 Worktree 收尾(Finding #08 + #09)

- **`CHANGELOG.md`**(本文件,新增)

### Changed

- **`.ai/intake-templates.md`** §A 探索式 Step 1:`散文输入` 现支持"C 模式分支",当 context.md 已就绪时跳过散文,直接从文件抽取(Finding #02)

### Removed

- **`.ai/prompts/05-claude-review.md`**(Finding #19 方案 B,**Breaking change**)
  - 原因:E1 实战中 4 个 Slice + 3 轮 fix + 2 轮 verify 全过程 **05 从未作为独立 step 被调用**;Claude review 实际以 main session 协作者形式在 chat 内发生
  - 替代:OC review 三步法 + escalation 路径;触发条件归入 workflow.md §5.2
  - 影响:外部如果有项目脚本引用了 `.ai/prompts/05-claude-review.md`,需改为 `.ai/prompts/04-opencode-review.md` 的 escalation 分支

### Deferred to v2.1+

- **Finding #11**: 二组 paths 对 Java 多层结构不够(P3)— 仅 Java 项目相关,starter 语言中立,推迟到专题 v2.1
- **Finding #16**: Mockito inline 在 macOS 失败(P2)— 环境特定问题,通用建议太抽象,推迟到积累更多生态信号后

### Validation

本次升级基于 **PaymentRecon E1** 异构验证完成:

- 项目栈:Java 17 + Spring Boot 3 + PostgreSQL + Maven + MyBatis + Testcontainers(与 starter v1.0 验证的 Go/Vue/Web 栈完全异构)
- 业务域:聚合支付平台 T+1 单渠道对账子系统(金融批处理,与 v1.0 IoT/web 域异构)
- 规模:4 个 Slice + 1 个 epic-closeout 批次 + 9 条 RV finding(全部 verified 或 subsumed)+ 18 条 starter finding
- 测试:19/19 PASS(单元 + Testcontainers 集成 + MockMvc E2E)
- 工作流闸门:`Scope → Architecture → Quality` 三步法在 S2/S3/S4 三个连续 Slice 上表现一致

详细复盘见 `payment-recon-demo/.ai/logs/e1-validation-report.md`(独立项目)。

---

## [v1.0.0] — 2026-05-13

### Added

初始发布:基于 DeviceOps 项目 dogfood 沉淀的 8 prompt + intake skill + workflow 框架。

- 8 个 prompts(`01-opencode-context.md` ... `08-codex-audit.md`)
- `intake` skill(探索式 / 问答式 / Agent 全权设计)
- `workflow.md` 七阶段流程
- `state.md` / `progress.md` / `decisions.md` / `review.md` 协作产物模板
- `init-collab.sh` bootstrap 脚本

[v2.0.0]: https://github.com/<user>/ai-collab-starter/releases/tag/v2.0.0
[v1.0.0]: https://github.com/<user>/ai-collab-starter/releases/tag/v1.0.0
