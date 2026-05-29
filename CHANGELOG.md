# Changelog

All notable changes to **ai-collab-starter** are documented here.

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html):
- **MAJOR** version when breaking changes to the workflow contract (prompts removed/merged, file paths renamed)
- **MINOR** version when adding capabilities backwards-compatibly
- **PATCH** version when fixing typos / wording / non-structural improvements

---

## [v5.3.0-rc1] — 2026-05-29

### TL;DR

消化 DeviceOps M3-Beta + M3-Beta-Scale dogfood 4 findings(#28/29/30/31)。MINOR:引入 review 第 4 verdict 值 `NEEDS-EXECUTION` + E2E/真机切片专项检查 + lifecycle 闭环测试纪律 + Epic 收口「回归 verdict 不可 split 替代」+ archive 脚本默认 root 修复。无 breaking change。

> ⚠️ 本版本待实战 dogfood 验证后翻 stable。rc1+rc2 的既有约束(finding-23 probe / finding-24 listener / finding-25 RV status / finding-26 state 红线 / finding-27 progress 自检 / m2-finding-01 多决策交叉 / m2-finding-02 Epic 全量闸门)已在 DeviceOps M3-Beta-Scale 全 epic 实战验证生效;本 v5.3.0-rc1 的**新增 patch** 待下一轮 derived 实战后与 rc2 一并翻 stable。

### 实战数据

DeviceOps M3-Beta-Scale epic(5 slice · fleet 30→60→100 Docker ramp + 跨仓 telemetry + 真机 ground-truth · CLOSED 2026-05-29)dogfood 暴露 4 个 starter 协议缺口:#28 Scout 把模板占位符 epic 误判 PASS escalate;#29 archive 脚本默认扫 starter 自己;#30 telemetry 单点写入测试漏 lifecycle overwrite(P1 RV-11);#31 split evidence 差点替代 AC 点名的 Alpha 回归绿 verdict(S5 review 拦下)。

### Added

- **`NEEDS-EXECUTION` review verdict(第 4 值)**(`04-review.md` / `state.md` template / `06-fix.md` / `workflow.md` · deviceops-finding-28):`PASS / PATCH / REJECT / NEEDS-EXECUTION` 四值。NEEDS-EXECUTION = 设计完整但真机/E2E/集成测试未跑或证据是模板占位符,既非 fail 也非 PASS,返回 Impl 跑测试+回填。明确与 finding-25 的 finding `Status` 7 值是**两条轴**,勿混。
- **E2E / 真机 / 集成切片专项检查**(`04-review.md` · deviceops-finding-28):三步法之外加三项——模板vs实测数据(grep `{{VAR}}`/`<TODO>`/`TBD`)、脚本可跑vs已跑通(追实跑证据)、deferred 承接追踪(cross-check 前序 RV 承接路径)。
- **状态/telemetry 字段闭环测试纪律**(`03-implement.md` + `04-review.md` Quality 通用项 · deviceops-finding-30):跨多次上报累积的状态字段必须测完整 lifecycle 序列 + 服务端 overwrite vs sticky 核对。

### Changed

- **Epic 收口全量测试闸门加第 3 条**(`04-review.md` + `workflow.md` §5.4 · deviceops-finding-31):AC 明文要求「`--scenario=all` PASS」或「X 回归 suite PASS」时,closeout 必须有该脚本本身的绿 verdict,分场景 targeted PASS 不可替代;无绿 verdict 给「最小补跑 gate」。是 m2-finding-02 的精确化补丁。
- **`scripts/archive-progress.sh` 默认 root → `$PWD`**(deviceops-finding-29):旧默认 `$(dirname "$0")/..` 致 derived 项目绝对路径调用时误扫 starter 自己(silent 0 段假成功);改用 `$PWD` + 找不到时错误提示 + AGENTS.md 补「跑 archive 两前提」(从项目根跑 / 0 归档不一定 bug)。`DEVICEOPS_ROOT` 显式仍优先。

### Removed

无。

### Breaking changes

无。`NEEDS-EXECUTION` 是新增 verdict 值,不破坏既有 PASS/PATCH/REJECT 三值语义(向后兼容扩展)。

### Why these changes

- #28:DeviceOps M3-Beta S4,Scout escalate PASS 但 3 个 scenario log 全 `{{VAR}}` 占位符,Claude 复审 spot-check 才发现,多耗一轮 token。
- #29:M3-Beta-Scale intake 后 Human 跑 archive 建议,出 silent「0 段」误以为 bug;根因脚本默认扫 starter 自己。
- #30:M3-Beta-Scale S3 telemetry,`completion_path` 被后续 UNSPECIFIED 上报清空(P1 RV-11),Impl 单点 probe 测不出,Claude review 跑完整 lifecycle 才发现。
- #31:M3-Beta-Scale S5,Alpha 回归 23 run 全 SKIP + 1 incomplete,split evidence 差点替代「Alpha 回归 PASS」AC,Claude required review 拦下并指定最小 gate。

### 升级指南(derived 项目)

rc 版本默认不强推 `STARTER_VERSION`(rc 留 starter 自身实验,见 starter-upgrade-protocol Step 7)。derived 项目如需提前用 NEEDS-EXECUTION verdict / E2E 专项检查,rsync `.ai/prompts/{03,04,06}-*.md` + `.ai/workflow.md` + `scripts/archive-progress.sh` + AGENTS.md 对应段。stable 翻牌时一并带 rc1+rc2+本 rc1 全量增量。

---

## [v5.2.0-rc2] — 2026-05-24

> ⚠️ **Release candidate · 合并消化 rc1 · 待 dogfood 验证后翻 stable**。
> 本版本在 v5.2.0-rc1 基础上消化 DeviceOps M3-Beta dogfood 暴露的 5 条 finding
> （prompt / template 契约增量 + 维护规则补丁，0 独立 dogfood）。
> derived 项目默认仍 sync v5.1.0 stable；rc1 的 2 条与 rc2 的 5 条会一起在 stable 翻牌时落地。

### TL;DR

- **消化 inbox 5 条 finding**（2×P1 + 3×P2，全部来自 `from-deviceops` · DeviceOps M3-Beta S2/S3 dogfood）。
- 无 breaking change · 全部为增量 prompt 契约约束 / template 维护规则 / 收尾自检。
- inbox 现状：`from-deviceops` 0 条 pending（5 条已实施归档）；`from-lite-smart-uite` 6 条维持 deferred（lite 架构相关）；`from-payment-recon-demo` 不在本轮范畴。

### 实战数据

- 无独立 dogfood —— rc1 的 inbox 续摊 + 同批 DeviceOps M3-Beta dogfood 新增 finding 消化轮。
- 触发：Human 在 DeviceOps M3-Beta S2/S3 落 finding 后显式启动 starter 升级仪式。
- finding 来源：`from-deviceops/`（DeviceOps M3-Beta S2 ABBA 死锁 + libtorrent setter 反例 + S3 state.md 膨胀 / progress.md 零归档 / RV status 自创复合值，5 条均 2026-05-24 同批落档）。

### Added / Changed

#### `02-claude-plan.md`（deviceops-finding-23 / 24）

- 新增「**锁定外部 API 行为契约前必须最小复现验证**」P1 强约束段：ADR 锁第三方 API 具体值 /
  行为契约前必须双层验证（doc + 真机/桌面 getter probe），未明确定义的边界值禁止仅凭文档推断；
  落档 `.ai/logs/<adr-id>-api-probe.md`，ADR Decision 段引用。仅对外部不可控 API 强制。
- 新增「**Listener / Observer / Callback 类决策必须规约并发实现**」P1 强约束段：锁 listener
  pattern 等架构选择时必须同时锁定 4 项并发实现纪律（调用纪律 / Snapshot 策略 / 锁序约束 /
  生命周期纪律），并给出 snapshot + 解锁后调通用模板。不限语言，event-bus / observer 等同样适用。

#### `.ai/review.md` + `04-review.md` + `06-fix.md`（deviceops-finding-25）

- `.ai/review.md` template 顶部 Status semantics 段明文：**Status 字段只能用 7 种标准值之一**
  （`open | accepted | in-progress | fixed | verified | rejected | deferred`），**禁止自创复合值**
  （如 `fixed-with-deferred-E2E`）；子状态 / 承接路径放 Status 行括号注解，给出 3 条正确写法示例。
- `04-review.md` / `06-fix.md` 收尾段加同条自检提醒。

#### `.ai/state.md` + `02-claude-plan.md / 03-implement.md / 04-review.md`（deviceops-finding-26）

- `.ai/state.md` 维护规则段追加第 6 / 7 条：
  - 第 6 条「**state ≠ progress 红线**」：state.md 只承载 resume 最小快照，详细摸排发现 /
    token 统计 / drafting 备忘 / epic 教训复盘全部放别处；合理快照 ≤ 80 行。
  - 第 7 条「**Next step 可粘贴 prompt body 硬上限 15 行**」对齐 02-claude-plan.md 收尾段，
    自检 `wc -l` fence 内行数。
- 02 / 03 / 04 prompt 收尾「下一步提示词 + 刷新 state.md」段加 cross-reference，提醒严守第 6 / 7 条。

#### `AGENTS.md` + `03-implement.md / 04-review.md / 06-fix.md`（deviceops-finding-27）

- `AGENTS.md > Document State Hygiene` 段新增「**progress.md 行数自检**」小节：每个 Agent 收尾
  刷 state.md 前必须 `wc -l .ai/progress.md`，按三档阈值（< 500 / ≥ 500 / ≥ 2000）触发提醒
  或强制 archive。补齐 `scripts/archive-progress.sh` 工具与协议触发器之间的缺失环节。
- 03 / 04 / 06 prompt 收尾段加 cross-reference。

### Why these changes

- **finding-23**：DeviceOps M3-Beta ADR-20260523-02 amendment v1 锁 `set_max_uploads(0)` 仅
  基于 libtorrent header doc，未明确定义 `0` 语义；Impl 真机实测 getter 返回 16777215（unlimited
  哨兵）→ amendment v2 改 `(1, 5120)` 二次迭代，~30k token 浪费（P1 / RV-20260524-01）。Finding #22
  覆盖静态符号冲突，本约束补「动态行为验证」空白。
- **finding-24**：DeviceOps M3-Beta ADR D2 锁 listener pattern 架构但未锁并发实现，Impl 自由
  发挥写持锁内调 listener → 与 worker 线程形成 ABBA 死锁，Android Service 永久 hang，靠 Claude
  05-review 拦截（P1 / RV-20260524-02）。强约束 #1 覆盖水平维度（A/B/C 选一个），本约束补
  垂直维度（同一架构内的实现规约）。
- **finding-25**：DeviceOps M3-Beta Claude 在 RV-20260524-04 自创 `fixed-with-deferred-E2E`
  非标 status，破坏 grep / starter-status.sh 类工具一致性。template 列了 7 种值但没明文禁第 8 种。
- **finding-26**：DeviceOps M3-Beta S3 阶段 state.md 涨到 175 行（合理 ≤ 80），Next step prompt
  body 84 行（硬上限 15），packet R1-R7 全文 / token 统计 / 重复 Notes 全塞进 state.md。template
  维护规则缺「state ≠ progress」红线 + 缺 prompt body 行数自检 cross-reference。
- **finding-27**：DeviceOps 用 starter v5.0+ 约 18 个月，`scripts/archive-progress.sh` 自 May 10
  存在但**从未被任何 Agent 触发**，progress.md 涨到 3038 行才由人工 audit 发现。工具齐备但
  触发器空缺——同类问题 starter 已在 #02 / #26 验证过「工具 ≠ 触发，触发要靠协议」。

### Breaking changes

无。全部为增量契约约束 / 模板维护规则 / 收尾自检，v5.1.0 / v5.2.0-rc1 旧 task / brief / ADR / review.md
仍合法。derived 项目 sync 后只需在新 task / 新 review 中遵守新约束即可。

### 升级指南（derived 项目 sync）

> rc2 仍为 rc，默认不强推；等翻 stable 后再 sync。stable sync 时 `rsync` 新 `.ai/prompts/` +
> `.ai/state.md` + `.ai/review.md` + `AGENTS.md` 即可，无文件重命名、无 path 迁移。
>
> 已 sync 过 v5.1.0 的 derived 项目特别注意：v5.2.0 stable 翻牌时一次性带 rc1（2 条）+ rc2
> （5 条）= 7 条增量约束。

### 归档

- `.ai/logs/archived/v5.2.0-rc2-released/`：`deviceops-finding-23` / `deviceops-finding-24` /
  `deviceops-finding-25` / `deviceops-finding-26` / `deviceops-finding-27`。

---

## [v5.2.0-rc1] — 2026-05-22

> ⚠️ **Release candidate · 待实战 dogfood 验证后翻 stable**。
> 本版本消化 DeviceOps M2 dogfood 暴露的 2 条 finding（prompt 契约增量，0 实战 dogfood）。
> derived 项目默认仍 sync v5.1.0 stable。

### TL;DR

- **消化 inbox 2 条 finding**（2×P2，均来自 `from-deviceops` · DeviceOps M2-B/C/D dogfood）。
- 无 breaking change · 全部为增量 prompt 契约约束。
- inbox 现状：`from-deviceops` 2 条已实施归档；`from-lite-smart-uite` 6 条维持 deferred（lite 架构相关，未纳入本轮）。

### 实战数据

- 无独立 dogfood —— inbox 消化轮。触发：Human 在 DeviceOps M2 路线图全收口后显式启动 starter 升级仪式。
- finding 来源：`from-deviceops`（DeviceOps M2-B/C/D 三 epic dogfood，2026-05-22）。

### Added / Changed

#### `02-claude-plan.md`（deviceops-m2-finding-01）
- 新增「**多决策交叉检查**」强约束段：ADR 含 ≥ 2 条 Decision 时，必须做「决策 × 决策」交叉检查——
  列出每条 Decision 写/改的状态/资源/配置/limiter/单例，找出被多条 Decision 触碰的同一目标，
  在 ADR 显式声明主导方/写入顺序/冲突优先级，或论证彼此正交。

#### `04-review.md` + `workflow.md`（deviceops-m2-finding-02）
- `04-review.md` 新增「**Epic 收口全量测试闸门**」段：① 单切片 review 见非本切片起源失败测试须登 finding
  （不只标 observation）；② epic 末切片 review PASS 后、文档收口前必须全量复跑测试，红测试清零方可收口。
- `workflow.md` §5.4 新增同名段，交叉引用 04-review.md。

### Why these changes

- **finding-01**：DeviceOps M2-D ADR 的两条 Decision（D2 限速热加载 / D6 自动降速）都写 `limiter` BPS、
  意图相反，plan 阶段未发现 → 实施后自动降速被热加载每周期撤销（P1，RV-20260522-12）。02-claude-plan 原有
  强约束都是单决策维度，缺「决策交互」检查。
- **finding-02**：DeviceOps M2-D 末切片 review 见 `TestReportBandwidth` 失败、判「非本切片」标 observation
  放过；实为更早切片起源的时间炸弹 fixture，靠 epic 收口预检才抓到（RV-20260522-16）。缺 epic 收口的
  全量测试强制闸门。

### Breaking changes

无。全部为增量契约约束，v5.1.0 旧 task / brief / ADR 仍合法。

### 升级指南（derived 项目 sync）

> rc 默认不强推；等翻 stable 后再 sync。stable sync 时 `rsync` 新 `.ai/prompts/` + `workflow.md` 即可，无文件重命名。

### 归档

- `.ai/logs/archived/v5.2.0-released/`：`deviceops-m2-finding-01` / `deviceops-m2-finding-02`。

---

## [v5.1.0] — 2026-05-22

> ✅ **Stable** — 由 v5.1.0-rc1 graduate（rc1 发布于 2026-05-20）。
> rc1 经 DeviceOps **M2-B / M2-C / M2-D 三个 epic 实战 dogfood** 验证：全流程 intake → Scout →
> Claude plan → Impl → review 跑通，PASS 与 PATCH→fix→verify 全路径、frontmatter `required`/`auto`
> 多源触发均经实战，未撞 prompt 契约硬伤。本版本内容与 v5.1.0-rc1 完全一致，仅 graduate 为 stable。
> dogfood 暴露的 2 条新 finding 不属 rc1 内容范畴 → 归 v5.2.0（见下方 v5.2.0-rc1 段）。
> derived 项目可 sync v5.1.0 stable。

### TL;DR

- **消化 inbox 7 条 finding** (3×P2 + 3×P3 + 1×low) —— 来自 lite→main sync (lite v0.1 / v0.7 已实现 finding) + payment-recon-demo starter-v2 backlog。
- 无 breaking change · 全部为增量契约约束。
- inbox 19 条总盘点结果: **7 必修 / 5 拒收 (lite 架构专属) / 1 已实现 / 6 deferred**。

### 实战数据

- 无独立 dogfood —— inbox 消化轮。触发: Human 显式启动 main 升级仪式。
- finding 来源:
  - `from-payment-recon-demo` (2 条 starter-v2 backlog · 2026-05-13): finding-11 (Java 多层 paths) 采纳; finding-16 (Mockito inline/scope) 评估为 main 早已实现。
  - `from-lite-smart-uite` (lite→main sync): lite v0.7 的 F07-F10 + lite v0.1 的 F05/F12 采纳; lite v0.1 的 F09/F11/F14/F15/F16 拒收 (target lite 专属文件, main 无对应)。

### Added / Changed

#### `02-claude-plan.md` (4 finding)
- **lite-v0.1-12 软条件漏洞**: 「决策必须落到唯一具体选择」禁止清单补 4 类软条件措辞 (或等价 / 仅当需要 / 若有必要 / 可考虑)。
- **lite-v0.1-05 Alternatives UX 维度**: 新增「Alternatives 必须覆盖 UX/行为等价维度」段 —— 不能只对比技术实现不同的方案。
- **F09-v0.7 依赖闭包优先诊断**: 新增「根因诊断方法: linkage 类 bug 依赖闭包优先」段 —— linkage 类 bug 第一轮先跑完整传递依赖闭包扫描。
- **starter-v2-finding-11 Java 多层 paths**: Paths 二组分段补「Java 多层结构核心组超 8 文件时再分子标题 (业务逻辑层 / 配置映射层)」。

#### `04-review.md` (3 finding)
- **F10-v0.7 PowerShell review 行**: 第三步语言自适应 quality 表新增 PowerShell / Windows 脚本行 (drive-qualified 变量陷阱等)。
- **F07-v0.7 verifier 脚本规模例外**: 新增段 —— C2 规模启发对 dedicated verifier/test 脚本不直接 escalate (脚本天然 gate 密集偏长)。
- **F08-v0.7 verify-don't-trust**: 新增段 —— Impl 报「环境不可达」类 blocker 时, review 先用标准执行入口自验, 不直接采信。

#### `03-implement.md` (1 finding)
- **F08-v0.7 环境 blocker 上报纪律**: 新增段 —— 上报环境 blocker 前必须用 task 标准执行入口尝试过, 禁止把「不会跑」包装成「环境不可达」写进 progress.md。

### Why these changes

- F07-F10 来自 lite v0.7 dogfood (smart-uite 两个 P0 epic): verifier 脚本撞行数 cap、Impl 谎报 SSH 不可达、依赖闭包链式挖掘、PowerShell parser 陷阱。
- lite-v0.1-05/12 来自 lite 早期 dogfood, 通用决策纪律, 同样适用 main 的 02-claude-plan。
- starter-v2-finding-11 是 payment-recon-demo Java Spring 实战暴露的 paths 二分信号不足。

### Breaking changes

无。全部为增量契约约束, v5.0.0 旧 task / brief / ADR 仍合法。

### 升级指南 (derived 项目 sync)

> rc 默认不强推; 等翻 stable 后再 sync。stable sync 时 `rsync` 新 `.ai/prompts/` 即可, 无文件重命名。

### 未消化 (留 inbox)

`from-lite-smart-uite/` 保留 6 条 deferred (lite-v0.1-02/03/06/07/10/13): state 漂移纪律 / GitNexus 一等公民 / severity-escalation 映射 / 复现纪律 / bug 回归 revert / 阶段枚举 —— spirit 适用 main 但需逐个核对 main 现状, 留下次升级仪式。

---

## [v5.0.0-rc1] — 2026-05-20

> ⚠️ **Release candidate · 待实战 dogfood 验证后翻 stable**。
> 本版本是纯命名重构 (0 实战 dogfood)。derived 项目默认仍 sync v3.0.0 stable。

> 🔨 **MAJOR · breaking change**: 角色名 `Codex → Impl`、`OpenCode → Scout`,6 个 prompt 文件去工具品牌前缀。`Claude` 角色名保留不变。

### TL;DR

- **工具无关命名重构**: 角色名描述职责而非工具品牌 —— `Codex → Impl`(实施层)、`OpenCode → Scout`(低成本先锁层:摸排/廉价审/草稿)。`Claude` 保留(main 的架构决策定位本就以 Claude 为核心)。
- 6 个 prompt 文件重命名去工具前缀;`02-claude-plan.md` 保留(Claude 不变)。
- 触发: lite 产品线已于 `v0.7.0-lite-rc1` 做同类重构 (lite finding F11-v0.7); Human 要求 main 同步做工具无关命名, 以便切换底层 agent 工具 (如 Codex CLI → 其它) 时框架命名不失效。

### 实战数据

- 无独立 dogfood —— 命名重构, 由 lite v0.7 重构 + Human 工具栈决策驱动。
- lite 侧同源重构: `ai-collab-starter-lite` `v0.7.0-lite-rc1` 已落地 (`Codex→Lead` / `OC-*→Helper/Impl/Reviewer`)。main 角色拓扑不同 (3 角色 vs lite 4 角色), 故映射不同。

### Breaking changes (MAJOR)

**角色重命名**:

| 旧名 | 新名 | 职责 |
|------|------|------|
| Codex | **Impl** | 实施 (03) / 修复 (06) / 草稿审校 (08) |
| OpenCode | **Scout** | 上下文摸排 (01) / 低成本 review (04) / 草稿实施 (07) |
| Claude / Claude Code | *(不变)* | 架构决策 / 高风险评审 |

**prompt 文件重命名**:

```
01-opencode-context.md  → 01-context.md
03-codex-implement.md   → 03-implement.md
04-opencode-review.md   → 04-review.md
06-codex-fix.md         → 06-fix.md
07-opencode-draft.md    → 07-draft.md
08-codex-audit.md       → 08-audit.md
02-claude-plan.md       → (不变 · Claude 保留)
```

**其它 token**: TODO 标记 `TODO(codex-review) → TODO(impl-review)`;全仓 prose / 阶段枚举 / 触发来源表里 `Codex/OpenCode/OC` 角色引用全部 sync 到新名。

### Changed

- 全仓角色 token 替换: `.ai/prompts/` (7 文件) / `workflow.md` / `state.md` / `AGENTS.md` / `getting-started.md` / `intake-templates.md` / `token-strategy.md` / `review.md` / `README.md` / `STRUCTURE.md`
- `decisions.md` / `progress.md` / `CHANGELOG.md` 历史段**不动** (append-only 历史记录, 保留旧名)

### 升级指南 (derived 项目 sync)

> rc 默认不强推; 等翻 stable 后再 sync。stable sync 时:

1. `rsync` 新 `.ai/prompts/` (6 个文件名变更, 旧文件需删除; `02-claude-plan.md` 不变)
2. 项目内引用旧 prompt 路径 / 旧角色名的文档按 Breaking changes 映射表替换
3. 旧 epic 归档 / decisions.md 不动 (历史保留旧名)

---

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
