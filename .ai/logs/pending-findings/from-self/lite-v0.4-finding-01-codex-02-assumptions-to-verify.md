---
finding-id: lite-v0.4-finding-01-codex-02-assumptions-to-verify
severity: P2
category: prompt
source-project: lite-self (v0.4.0-lite-rc1 dogfood · smart-uite dcbusinessmanager-h5coat-start-fails bug 02-plan-refine 阶段)
discovered: 2026-05-18
target:
  - .ai/prompts/02-codex-plan.md (输出格式末尾加 "Assumptions to verify (Human cross-check 必读)" 段 + 强约束 8 条)
  - .ai/state.md (触发条件加 "Human 审 Assumptions to verify 后放行" 选项)
  - .ai/prompts/04-opencode-review.md (3b 自审盲点加 B9 "Brief 假设 vs evidence 一致性 cross-check" 兜底)
status: pending
related: [F04-self, F05-self, F06-self]
---

# Finding F01-v0.5: 02-codex-plan.md 缺 "Assumptions to verify by Human" 强约束 / Codex 不主动 flag brief 假设歧义给 Human

## 现象

smart-uite v0.4.0-lite-rc1 dogfood (dcbusinessmanager-h5coat-start-fails P0 bug 02-plan-refine 阶段, 2026-05-18 19:48):

**Brief 描述**: User + Codex 01-intake 反复说 "**DcBusinessManager** 托盘菜单启动 H5 外壳"

**Codex 02 L2 摸排 GitNexus evidence 全在 `DcReaderService/` 仓**:
- `DcReaderService/trayclass.cpp:65-66` — tray menu QAction("启动H5外壳")
- `DcReaderService/mainwindow.cpp:52` — signal connect to `slot_ShowH5coat`
- `DcReaderService/mainwindow.cpp:1209-1237` — `H5ActivateOrLaunch()` 启动 H5Coat
- `DcReaderService/businesssettingmodel.cpp` — `StartH5Bit/Type32Bit` 配置

**命名歧义存在** (但 Codex 没在 brief / scratch / state.md 任一处 flag):
- (a) smart-uite 命名约定: `DcBusinessManager.exe` binary 用 `DcReaderService/*.cpp` 代码编译 ("业务管家" 是品牌名, code 里叫 DcReaderService)
- (b) DcBusinessManager 是 wrapper, 实际 H5 启动在 DcReaderService 内
- (c) Codex 找错方向了

Claude (外部审计者) cross-check brief 描述 vs scratch evidence 时发现这个歧义并 flag 给 Human, **但生产环境没 Claude 实时审, 这条歧义会 silently 透过 02 进入 03**, 若假设错则 03/04 一整轮浪费 (OC-impl 改错地方, 03c 验收过, 04 review cleanup 也按错假设跑)。

## 影响

- **严重浪费**: brief 命名 / 跨子项目 / 类型假设错时, 03b 一整轮 (含 OC-impl 写代码 + 03c verify + 04 review) 都按错假设跑, 最后 merge 才发现 → 至少浪费 2-4h
- **Pattern A 信任度下降**: Human 接力时只看 state.md / brief, 看不到 scratch 里的 evidence, 自然不会 cross-check
- **不可预测性**: 当前 Codex 偶尔会主动 flag (运气好), 多数时候不会; 换 LLM / 不同 session 表现差异大
- **lite 设计意图 partial 失效**: lite 强调 "force Codex 做 trade-off", brief 假设是 trade-off 的前置数据, 数据假设错则 trade-off 失效

## 根因

### 契约盲区 1: 02-codex-plan.md 强约束 1-7 没"假设主动 flag"项

当前强约束:
1. Alternatives considered ≥ 2 (+ UX 维度 · F05)
2. Data Contract L1-L5 分级
3. Negative consequences ≥ 1
4. Pre-decisions ≥ 3 锁 (frontmatter)
5. Paths 二组分
6. 锁定符号名前 grep 同包预检 (v0.2 工具优先级 · F03)
7. OC delegation candidates (三类 · F04)

**漏**: "Brief 描述 vs evidence 路径 cross-check, 不一致主动 flag"

### 契约盲区 2: Codex 02 输出格式没"假设段"

当前输出格式末尾 (`02-codex-plan.md` 文末模板) 只列:
- Decision
- Rationale
- Alternatives considered
- Pre-decisions
- Compatibility and rollout
- Implementation slices
- Required tests
- Review focus
- OC delegation candidates
- Decision record (ADR-YYYYMMDD-NN)

**漏**: "Assumptions to verify by Human (Human cross-check 必读)" 段, 强制 Codex 列 ≥ 1 个假设让 Human 看。

### 契约盲区 3: state.md 触发条件不含 "Assumptions 待 Human 审"

state.md `Next step.触发条件(lite)` 字段当前枚举:
- `A · pre-declared` (frontmatter 预声明)
- `C · OC escalation`
- `H · 重试上限`
- `normal · 标准路径`

**漏**: "Assumptions to verify 段非空时, Human 必审才能进 03a" 流转分支。

### 与 F04-self / F05-self / F06-self 同形态

- F04-self (intake evidence ingestion): Codex 不主动 read evidence → 加 Step 1.5 force
- F05-self (子任务包必做 override 03b): Codex 03a 写越权 → 加禁止项 + 优先级
- F06-self (B7 HTML 注释闭合 + re-review 不自审): Codex / OC-review 不主动自审 → 加验证 + 钩子
- **F01-v0.5 (本)**: Codex 02 不主动 cross-check / flag 假设 → 加"Assumptions to verify"段 force

都是"靠 Agent 个体不可靠 → contract force"的同形态修复。

## 证据

- smart-uite 2026-05-18 19:48:53 02-plan-refine 阶段:
  - brief 文件 `.ai/tasks/bug-20260518-dcbusinessmanager-h5coat-start-fails.md` (67 行): 反复用 "DcBusinessManager", 没 cross-check / flag
  - scratch/gitnexus-*.md (Codex 自跑 GitNexus 产物, 27 行): evidence 全在 `DcReaderService/`, **没显式声明命名映射**
  - scratch/req-*.md (OC-helper req): pattern 含 `signal_showH5Coat|slot_ShowH5coat|H5ActivateOrLaunch`, 也都是 DcReaderService 符号, **没在 intent 段 cross-check 命名**
- Claude (本审计者) 在 Step "Codex 02 audit" 中显式发现 + 提示 Human cross-check
- Human 后续会询问 Codex 一次 yes/no — **这个 cross-check 应该是 Codex 主动产出, 不应 Human 后知后觉问**

## 提议修复 (方案 A · 最务实)

### 1. **`02-codex-plan.md > 强约束`** 加第 8 条

```markdown
### 8. Assumptions to verify by Human (v0.5 · F01-v0.5)

Brief 描述里的**关键假设** (类型识别 / 命名映射 / 跨子项目调用 / 32-64 位等架构敏感选择) 必须显式标在 02 输出末尾 `## Assumptions to verify` 段, 让 Human cross-check。

#### 必须列的假设类型 (任一命中 → 必列)

- **命名歧义**: Brief 描述路径 (e.g. "DcBusinessManager 托盘菜单") vs evidence 实际路径 (e.g. `DcReaderService/trayclass.cpp`) 不一致 — **必列**
- **binary 名 vs source 子仓名映射**: 当二进制名跟代码所在子仓名不同 (e.g. binary `DcBusinessManager.exe` 用 `DcReaderService/` 代码编译) — **必列**
- **跨子项目调用链假设**: 涉及 wrapper / inheritance / 反射 / IPC / proto 序列化 等不直观调用关系 — **必列**
- **架构敏感选择假设**: 32 vs 64 位 / Windows vs Linux / 调试 vs Release / 字符编码 (GBK vs UTF-8) / 工作目录依赖 等 — **必列**
- **L2 摸排无 evidence 的子句**: 02 brief 任一句陈述若 L2 摸排没有 ≥ 1 条 evidence 支持 — **必列**

#### 例外: 真无假设

若 02 L2 摸排 evidence 完全闭环 (每个 brief 陈述都有 evidence 支持 + 无命名歧义 + 无架构敏感选择), 显式标:
```
## Assumptions to verify

**无假设, evidence 闭环 confirmed** · 理由: L2 摸排 N 条 evidence 全部 1:1 命中 brief 陈述, 无命名歧义 / 跨子项目假设 / 架构选择歧义。
```

**但若 brief frontmatter `human-escalation-suggested: true` 或 `severity: P0/P1`, 必须列 ≥ 1 项**, 不允许 "无假设" 兜底 (P0/P1 风险高, 强制 cross-check)。

#### 反例 (dogfood 留底 · v0.5)

❌ Codex 02 brief 反复说 "DcBusinessManager 托盘菜单", 但 GitNexus evidence 全在 `DcReaderService/`, 没列假设 — Claude 外部审计才发现, 生产环境若没审则浪费下游一整轮
✅ Codex 02 brief 描述 "DcBusinessManager 托盘菜单", 末尾 Assumptions 段列 A1: "binary `DcBusinessManager.exe` 用 `DcReaderService/*.cpp` 编译 (隐式) · evidence: `JsCoat/CMakeLists.txt:N` install target / `DcReaderService/CMakeLists.txt` add_executable · cross-check 方式: Human 跑 `dumpbin /headers <bin>` 或 verify binary 命名 mapping"
```

### 2. **`02-codex-plan.md > 输出格式`** 末尾加固定段

```markdown
## Assumptions to verify (Human cross-check 必读 · v0.5)

> 若本段非空, state.md `Next step.触发条件 = "Human 审 Assumptions 后放行 03a"`, Human 必看必反馈才能进下游。

- **A1**: <一句话假设> · evidence: <file:line / path> · cross-check 方式: <Human 看哪 / 跑什么命令>
- **A2**: ...
- (若真无假设 + 非 P0/P1, 显式标 "无假设, evidence 闭环 confirmed")
```

### 3. **`state.md > Next step.触发条件(lite)`** 注释扩展

```markdown
- 触发条件(lite): NONE <!--
     A · pre-declared (frontmatter 预声明)
     C · OC escalation
     H · 重试上限
     normal · 标准路径
     X · Assumptions to verify (v0.5 · F01-v0.5 · 02 brief Assumptions 段非空 → Human 必审才能进 03a)
     -->
```

### 4. **`04-opencode-review.md > 3b 自审盲点`** 加 B9 兜底

```markdown
- [ ] **B9** (v0.5 · F01-v0.5). Brief 假设 vs evidence 一致性 cross-check
  - 验证方法:
    - 读 brief Assumptions 段, 检查每条 A_N 是否后续 (03a/03b) 被实际验证 (e.g. Human reply / commit message / progress.md 记录)
    - 若 brief Assumptions 段**为空** 但 brief frontmatter `human-escalation-suggested: true` / `P0/P1` → **B9 fail** (Codex 02 偷工, 漏列假设, 应升 Human 重审 02)
    - 若 brief Assumptions 段**有列** 但 Human 没 reply (state.md / progress.md 无对应 cross-check 记录) → **B9 warn** (假设未 confirmed 就进 03 风险)
  - 严重度: P2 (lite 系统级风险, 假设错则整轮浪费)
```

## SemVer 影响

**MINOR** (新增强约束 8 + 输出格式段 + state.md 触发条件分支 + 04 B9 · 不破坏 v0.4 旧 brief · 旧 brief 无 Assumptions 段仍合法只是不达 v0.5 best practice · 新 brief 必须 force 列假设或显式声明"无假设")。

## 关联与对照

- 与 **F04-self** (intake evidence ingestion) 同形态: F04-self 是"01-intake 不主动 read evidence", F01-v0.5 是"02 不主动 flag 假设歧义". 都是 Codex 个体不可靠 → contract force
- 与 **F05-self** (子任务包必做 override 03b 契约) 同形态: 都是 contract 盲区让 Agent 越界 / 漂移
- 与 **F06-self** (B7 HTML 注释闭合 + re-review 不自审) 同形态: 都是 Agent 不主动 self-check, framework 加 hook
- 与 **F07** (Reproduction 复现未确认纪律) 协同: F07 force "Reproduction 未确认 → L2 摸排", F01-v0.5 force "L2 摸排后 → Assumptions 显式 flag 给 Human"
- 与 **lite 设计意图**: lite 强调 "Codex force trade-off" + "Pattern A Human 接力", F01-v0.5 让 Human 接力时有更明确的 cross-check 入口 (Assumptions 段)
