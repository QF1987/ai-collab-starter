# ai-collab-starter-lite v0.1.0 设计文档 (v2 · 无协议版)

> **状态**: design freeze v2 · 2026-05-16
> **v1 归档**: `.ai/lite-v0.1.0-design-v1-acp-archived.md`(ACP/MCP 协议版, 已否决)
> **下次 session 启动指南**: 见末尾 §11
> **预计实施工时**: 2.5-3 h(从 v1 的 6h 大幅缩减, 因删除 ACP server)
> **作者**: Claude(本 session) + Human(决策)
> **触发来源**: Human 提议 "切独立分支跑 Codex+OC, Codex 脑力 OC 体力"

---

## 0 · v2 相对 v1 的核心变更 (必读)

| 议题 | v1 (2026-05-15) | v2 (2026-05-16) | 否决/采纳理由 |
|------|----------|----------|------|
| Codex↔OC 通信 | ACP via MCP(stdio server) | **Human 当 bus + 共享文件做总线** | ACP 已合并入 A2A 退场; MCP server 维护成本与 lite 极简定位矛盾 |
| Codex 03 是否写代码 | 是(Codex 实施) | **否, Codex 不写代码** | Human 决策: 给 OC 写代码的机会, Codex 改当 lead engineer (拆任务 + 验收) |
| OC 是否写代码 | 否(只读, 受调度) | **是, 03b 写代码主力** | 同上 |
| OC 代码质量保障 | 无(因 OC 不写) | **8 维 rubric + 5 硬门槛, 16/24 通过** | 新增 |
| 03b → 03c 重试 | N/A | **最多 3 轮, 超限升 Human 决策** | 防 Codex/OC 死锁 |
| 终端数量 (per epic) | 2 (Codex + OC) | **4 (Codex + OC-helper + OC-impl + OC-review)** | session 强隔离防自审盲点 |
| grep/scan 谁做 | OC (经 ACP) | **全仓搜索走 OC-helper, 有限范围 Codex 自己** | 规则清晰, 不依赖 Codex 估算 |
| 工时估算 | ~6 h | **~2.5-3 h** | 删除 MCP server 实施 |

---

## 1 · 项目定位

`ai-collab-starter-lite`(下称 **lite**) 是 `ai-collab-starter`(下称 **main**) 的独立产品线, **2 Agent + 1 Human** 协同框架, 适配以下场景:

- 没有 Claude API 预算 / 配额受限
- 隐私敏感, 需 air-gapped(Codex CLI + OpenCode 走 local 模型)
- 个人 / 小团队项目, 不需要 Opus 级架构 LLM
- **Codex 脑力(架构 + 拆任务 + 验收) + OC 体力(实施 + 独立审 + 信息查询)** 范式探索

| 角色 | 模型示例 | $/MTok(in/out) | 职责简述 |
|------|---------|---------------|--------|
| **Codex**(脑力, lead engineer) | GPT-5.5 等 | $3 / $15 | 02 plan + 03a 拆任务 + 03c 验收, 不写代码 |
| **OC-impl**(写代码主力) | DeepSeek-V4-Pro / 国产 | $0.3 / $1.5 | 03b 按 Codex prompt 写代码 |
| **OC-review**(独立审) | 同上 | 同上 | 04 三步法 + Codex 自审盲点专项 |
| **OC-helper**(信息查询) | 同上 | 同上 | 全仓 grep / scan / summarize, 结果写共享文件 |
| **Human** | — | — | message bus + 决策 gate + escalation 接收方 |

**单 slice 成本估算**(粗略, 实际看模型):
- Codex 02(thinking + plan): ~$0.10
- Codex 03a(decompose) + 03c(verify, 假定 1 轮通过): ~$0.05
- OC-impl(03b 写代码): ~$0.01
- OC-helper(0-2 次 grep): ~$0.005
- OC-review(04 独立审): ~$0.008
- **每 slice 总: ~$0.17** (vs main ~$0.35, 节省 ~52%)
- 若 03b→03c 走满 3 轮: 总 ~$0.20

## 2 · 与 main 的关系

`lite` 是 **独立产品线**(独立 SemVer, 独立 CHANGELOG), 不是 main 的 branch。
两者通过 **双向 finding sync 协议** 共享演化经验(详见 §8)。

| 维度 | main (v4.0-rc1+) | lite (v0.1.0+) |
|------|----------|---------|
| Agent 角色 | Claude(架构) + Codex(实施) + OC(审) | Codex(架构+拆任务+验收) + OC-impl/helper/review + Human |
| 02-plan owner | Claude | **Codex** |
| 03-implement 写代码方 | Codex | **OC-impl**(Codex 拆任务并验收) |
| 03 期信息查询 | Codex 自己 grep | **全仓搜索走 OC-helper, 有限范围 Codex 自己** |
| 04-review owner | OC | OC(同, 但 review 强约束更严, 含"Codex 自审盲点"专项) |
| Escalation 接收方 | Claude main session | **Human** |
| 跨 Agent 通信 | 无 | **Human 当 bus + 文件做总线**(`.ai/scratch/oc-helper/`) |
| SemVer | 独立 | 独立 |
| 升级仪式 | starter-upgrade-protocol.md(Claude 主导) | lite-upgrade-protocol.md(Human 主导, OC 辅助) |
| 终端数(per epic) | 2-3 | **4** (Codex + 3 OC) |

## 3 · Codex↔OC 手动转交协议 (替代 v1 的 ACP)

### 3.1 设计哲学

**"无协议, 文件即真相, Human 当触发器"** — 不引入任何跨 Agent 通信协议, 所有跨 session 信息流通过两种途径:

1. **chat 内容手动复制**(短指令, e.g. "去跑 req-E3-2")
2. **共享文件读写**(长内容, e.g. grep 全仓结果)

### 3.2 4 终端拓扑

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ T1: Codex    │   │ T2:OC-helper │   │ T3: OC-impl  │   │ T4: OC-review│
│ (主驱动)      │   │ (grep/scan)  │   │ (写代码)      │   │ (独立审)      │
│ 长 session    │   │ 长 session    │   │ 长 session    │   │ 长 session    │
│ per epic     │   │ per epic     │   │ per epic     │   │ per epic     │
└──────┬───────┘   └──────▲───────┘   └──────▲───────┘   └──────▲───────┘
       │                  │                  │                  │
       │                  └────┐  ┌──────────┘  ┌───────────────┘
       │                       │  │             │
       │ 输出指令/请求块/文件路径  │  │             │
       └────────► ┌─────────────┴──┴─────────────┘
                  │      Human (message bus)       │
                  │ 复制 prompt / 说 "done" / 转交  │
                  └─────────────────────────────────┘
```

### 3.3 session 隔离规则 (强制)

| 场景 | 规则 |
|------|------|
| 一个 epic 内的多轮 03b OC-impl | **同一 session 内继续** (保留 Codex 反馈历史) |
| 一个 epic 内的多轮 04 OC-review | **同一 session 内继续** (review→fix→review 循环) |
| 一个 epic 内 OC-helper 多次查询 | **同一 session 内继续** (查询任务大同小异) |
| **03b ↔ 04 (不同阶段之间)** | **必须新 session** (防自审盲点) |
| 不同 epic 之间 | 全部新 session (隔离上下文污染) |

一句话: **阶段内连续, 阶段间隔离, epic 间清零**。

### 3.4 OC-helper 共享文件协议

#### 3.4.1 触发条件

**全仓搜索(无 path 限制 / path 是整个 repo 根)走 OC-helper, 有限范围 Codex 自己**。

具体边界:
- ✅ 走 helper: `grep "foo" .`, `scan all internal/`, `summarize whole CHANGELOG.md`
- ❌ Codex 自己: `grep "foo" path/to/specific/file.go`, `read 3 个已知文件`

#### 3.4.2 目录约定

```
.ai/scratch/oc-helper/
├── req-<epic-id>-<n>.md      ← Codex 写: 给 OC-helper 的请求
└── out-<epic-id>-<n>.md      ← OC-helper 写: 结果回 Codex
```

`.gitignore` 加入 `.ai/scratch/oc-helper/` (临时文件, 不入版本控制; epic 结束 Human 可清空)。

#### 3.4.3 req 文件模板

```markdown
# OC-helper request <epic-id>-<n>

## intent
(一句话: 为什么要做这事, e.g. "找 uploadFile 全部调用点, 准备改签名")

## action
- type: grep | scan | summarize
- pattern / path / file: ...
- context_lines: 3
- max_matches: 100

## output_file
.ai/scratch/oc-helper/out-<epic-id>-<n>.md

## output_format
- 若 grep: 每条 match `file:line | snippet`, 一行一条
- 若 scan: 每文件 `path | size | one-line-purpose`
- 若 summarize: 段落 + 末尾 "key symbols: [...]"
```

#### 3.4.4 out 文件模板

```markdown
# OC-helper output <epic-id>-<n>

## status
- success | partial | failed
- total_matches: 47
- truncated: false

## result
(按 req 指定的 output_format)

## notes
(OC 自由文本: 异常 / 建议 / 它发现的可疑模式)
```

#### 3.4.5 Human bus 操作 SOP

1. Codex 在 T1 输出: `请让 OC-helper 跑 .ai/scratch/oc-helper/req-E3-2.md`
2. Human 切到 T2(OC-helper), 粘贴: `读 .ai/scratch/oc-helper/req-E3-2.md, 按里面 action 执行, 结果写到 output_file 指定路径`
3. OC-helper 跑完输出: `done`
4. Human 切回 T1: `OC-helper 跑完了`
5. Codex 自动 `read .ai/scratch/oc-helper/out-E3-2.md` 继续

### 3.5 OC-impl 转交协议

OC-impl 不走共享文件(实施期 patch 直接走 git, 不需要中转), 走 chat 复制:

1. Codex 在 T1 输出"OC-impl 子任务包"(下文 §6.1 模板)
2. Human 复制到 T3 (OC-impl), OC-impl 直接动 git working tree
3. OC-impl 输出: `done, 见 git diff`
4. Human 切回 T1: `OC-impl 完成, 请验收`
5. Codex 在 T1 `git diff` 自己看 → 走 §7 rubric 验收

### 3.6 OC-review 转交协议

同 OC-impl, 走 chat 复制:

1. Codex 03c 验收通过后, 在 T1 输出"OC-review 启动指令" (引用 task brief + diff 范围)
2. Human 复制到 T4 (OC-review)
3. OC-review 跑 04 三步法, 输出 findings markdown
4. Human 复制 findings 回 T1, Codex 判断: 严重 finding → 升 Human gate; 轻微 → 继续

## 4 · lite 分支文件改造清单

从 main v4.0-rc1 fork 后, 必改文件:

| 文件 | 改动 | 工时 |
|------|------|------|
| `.ai/prompts/02-claude-plan.md` | **删除**, 替换为 `02-codex-plan.md`(详见 §5) | 50 min |
| `.ai/prompts/03-codex-implement.md` | **重写**为 `03-codex-orchestrate.md`: Codex 改当 lead engineer, 不写代码; 含 03a 拆任务 + 03c 验收两段(详见 §6) | 40 min |
| **新增** `.ai/prompts/03b-opencode-impl.md` | OC-impl 写代码的强约束 prompt(只动 brief 指定 paths / 不翻案 pre-decisions / 输出 git diff) | 25 min |
| `.ai/prompts/04-opencode-review.md` | escalation 路径 Claude → Human; 三步法新增 "Codex 自审盲点专项检查"(catch 拆任务粗糙 / 验收偷工) | 30 min |
| **新增** `.ai/oc-code-quality-rubric.md` | 8 维度 + 5 硬门槛 rubric(详见 §7) | 30 min |
| **新增** `.ai/prompts/oc-helper.md` | OC-helper 通用 prompt(读 req 文件, 写 out 文件, 不动业务代码) | 15 min |
| `.ai/state.md`(template) | 删校验注释中 Claude 相关项; 触发来源 v4.0 4 类 → lite 3 类(A 改为 Codex 02 预声明, 删 Claude path) | 15 min |
| `.ai/workflow.md` | §3 架构 owner 改 Codex; 03 阶段拆为 03a/03b/03c; §5 escalation 改 Human; 整体术语换 Codex+OC×3+Human; 加 4 终端布局图 | 30 min |
| `.ai/starter-upgrade-protocol.md` → `lite-upgrade-protocol.md` | 7-step 中 Claude 步骤改 Codex + Human; 升级仪式由 Human 主导 | 30 min |
| `.ai/getting-started.md` | §〇 新 session 启动清单中, Claude 主动提醒改为 Human 看 status report; 加 4 终端开法说明 | 20 min |
| `AGENTS.md` | 重写: Codex lead + OC×3 + Human bus; 无协议设计哲学 | 30 min |
| `README.md` | 顶部加 "lite vs main" 段; 用户选 brand 时的决策矩阵; lite 强调"无协议、4 终端、文件总线" | 20 min |
| `CHANGELOG.md` | 起始 v0.1.0 段, 写明 fork from main v4.0-rc1 + 关键差异 + v1 设计(ACP)否决记录 | 15 min |
| `VERSION` | `v0.1.0-lite` | 1 min |
| `.gitignore` | 加 `.ai/scratch/` | 1 min |

总工时: **约 2.5-3 h** (vs v1 估的 6h, 因删除 MCP server 实施 + 共享文件协议比协议设计简单)

## 5 · 02-codex-plan.md 强约束设计

Codex 自然倾向"看到一种实现方式就走那条", 缺乏 trade-off 分析。`02-codex-plan.md` 必须**反 Codex 直觉**, force 7 件事:

### 强制条款 (草稿示意)

```markdown
# Prompt: Codex 架构与切片(lite v0.1.0)

## 角色

你是 Codex, 在 lite 分支承担 Claude 在 main 中的 02-plan 职责。
你天生擅长生成代码, 但**不擅长做 trade-off 决策**。本 prompt 强制你 force 这件事。

注意: lite 中 Codex **不写代码**, 你的产物是 task brief + 03a 阶段会用到的 OC 子任务包。
代码由 OC-impl 写, 你只拆任务 + 验收。

## 强约束 7 条 (任一不满足 → task brief 视为 invalid, 强制返工)

### 1. Alternatives considered 段不可少于 2 个方案
- 至少列 2 个被拒方案 + 各自被拒理由
- 拒绝理由不能是 "X 不好"; 必须是 "X 在本场景下因 Y 不适合"(具体)

### 2. Data Contract 五级分级
- L1 列语义 / L2 表结构 / L3 数据级(SQL/migration 项目必填)
- L4 实体注解级 / L5 Mapper 接口级(Java/MyBatis/JPA 项目必填)
- 不涉及时显式标 N/A, 不能漏

### 3. Negative consequences 不可空
- 每条 ADR 至少列 1 项被牺牲能力 / 新增依赖 / 兼容性窗口
- 想不出 → 你没认真评估, 重写

### 4. Pre-decisions 显式锁 ≥ 3 条
- task brief 头部 frontmatter 必填 `pre-decisions: [D1, D2, D3, ...]`
- 每条 D 在 brief 主体展开为子段(D1.what, D1.alternatives, D1.rationale)
- 实施期 OC-impl 不允许翻案 D1-Dn 任何一条; Codex 03c 验收时硬检查

### 5. Paths 二组分(核心 / 连带), 与 main 同
(沿用 main v4.0-rc1 02-claude-plan.md 的 paths 二组分原则)

### 6. 锁定符号名前 grep 同包预检
(沿用 main Finding #22 修复, 见 02-claude-plan.md 同段)
**注: 此 grep 若超 path 限制是全仓 → 走 OC-helper**

### 7. OC delegation candidates 段
- 在 brief 末尾标 "OC delegation candidates": 哪些 03 实施期步骤会调 OC-helper, 哪些会包成 OC-impl 子任务
- 典型: "OC-helper: 扫 internal/ 目录定位现有 Mapper 实现"; "OC-impl 子任务包 1: 实现 Service.create() 含错误分支"
- 这一段让 OC 04 review 时能预期 OC 调用频率, 反查异常

## 输出格式
(沿用 main 02-claude-plan.md 同结构, 加 pre-decisions frontmatter + OC delegation 段)

## 收尾
- state.md `Next step.Agent = Codex`(进 03a-decompose)
- task frontmatter 加 `claude-review-required: false`(lite 无 Claude)
- 触发源: 默认 normal; 若 Codex 自觉本 task 超能力 → frontmatter 加 `human-escalation-suggested: true`
```

## 6 · Codex 03 三段式 (03a 拆任务 / 03b OC 写 / 03c 验收)

### 6.1 03a 拆任务: Codex 输出的"OC-impl 子任务包"模板

Codex 03a 把 brief 拆成 N 个 OC-impl 子任务包(每包 ≤ 1 个 slice, 通常 30 min 内能完成):

```markdown
# OC-impl 子任务包 <epic-id>-<n>

## 上下文
- task brief: <path>
- pre-decisions 摘要: D1=..., D2=..., D3=...
- 本子任务涉及的 paths(核心): file1, file2
- 本子任务涉及的 paths(连带, 允许小改): file3
- 严禁动的 paths: 其余全部

## 实施要求 (严格按下方执行, 任何偏离请输出原因不要自作主张)

### 必做
1. ...
2. ...

### 测试要求
- 新增 unit test 覆盖: ...
- 必须跑通命令: `<test cmd>`

### 风格要求
- 命名: ...
- 错误处理: 返回 error 不 panic / log + return
- 注释: 只在 why 不明显处加, 禁止重复代码意图

### 禁止
- 重构无关代码
- 翻案 pre-decisions D1-D3 任一条
- 单文件 diff > 200 行(超了停下来问)

## 验收标准 (Codex 03c 会用 rubric 打分)
见 `.ai/oc-code-quality-rubric.md`, 总分 ≥ 16/24 通过, 否则退回。

## 完成产出
- git working tree 已改, 等 Codex 03c 验收
- 输出 "done, 见 git diff" 即可, 不要总结自己改了什么(Codex 自己看 diff)
```

### 6.2 03b OC-impl 执行
- OC-impl session 不带 Codex 02 brief 上下文(只看子任务包 + 子任务包里引用的 brief 段落)
- 严格按子任务包执行, 不越界
- 完成后输出: `done, 见 git diff`

### 6.3 03c Codex 验收 (rubric)

Codex 03c 拿 `git diff` + brief + 子任务包, 用 `.ai/oc-code-quality-rubric.md` 打分:

```
流程:
1. 硬门槛 H1-H5 逐条 check, 任一 fail → 直接退回 OC-impl
2. 维度 D1-D8 逐项打分, 总分 ≥ 16/24 通过, < 16 退回
3. 通过 → state.md 进 04; 退回 → 输出"退回模板"喂回 OC-impl

退回模板:
---
Verify 不通过. 原因:
- [hard fail 列表 / 或维度低分理由]

修改要求:
1. ...
2. ...
保留: [OC 做对的地方, 显式列出, 避免它推倒重来]

轮次: X/3
- 若 X<3: 请按上述修改, 提交后重新 done
- 若 X=3: 不要再改了, 请输出"达到 3 轮上限, 升 Human 决策"
---
```

### 6.4 重试上限与升级路径

- **03b ↔ 03c 最多 3 轮**, 第 3 轮 verify 仍 fail → 升 Human
- Human 决策三选:
  - (a) Codex 接手改 (lite v0.1.0 默认: Codex 此时**临时获得写代码权限**, 但仅限本子任务包范围; 改完 state.md 标注 "human-override-codex-fix")
  - (b) OC 再试第 4 轮 (Human 给 OC 新 hint, 比如"看 file X 行 Y 的模式")
  - (c) 回到 02 重新拆任务 (brief 本身可能有问题, 重新切片)

## 7 · OC 代码质量 rubric (新增文件 `.ai/oc-code-quality-rubric.md`)

放在 `.ai/oc-code-quality-rubric.md`, Codex 03c 验收用。

```markdown
# OC 代码质量 rubric (lite v0.1.0)

## 用途
Codex 03c 验收 OC-impl 产出时, 按本 rubric 打分。
**统一门槛: 总分 ≥ 16/24 通过**, 不分核心/glue。
(slice 类型在 brief 里 Codex 已标注, 当上下文给打分用, 不分门槛)

## 硬门槛 (任一不过 → 直接退回, 不打分)

- [ ] H1. pre-decisions(brief frontmatter)无一条被违反
- [ ] H2. paths 二组分: OC 只动了"核心 paths" + 子任务包明确许可的"连带 paths"
- [ ] H3. 编译/lint/typecheck 通过 (Codex 本机跑)
- [ ] H4. 现有测试不退化 (新增测试可以失败, 但旧测试不能挂)
- [ ] H5. 无可疑大段改动: 单文件 diff > 200 行 → 自动 fail (除非 brief 显式预声明)

## 维度打分 (每维 0-3 分, 8 维度, 总分 24, 门槛 ≥ 16/24)

| 维度 | 0 (fail) | 1 (差) | 2 (合格) | 3 (好) |
|------|---------|--------|---------|--------|
| **D1. brief 完成度** | 漏关键需求 | 完成 60-80% | 100% | 100% + 边界全覆盖 |
| **D2. 代码可读性** | 命名/结构混乱 | 能读懂但啰嗦 | 清晰直接 | 简洁且自解释 |
| **D3. 测试质量** | 无/假测试 | 只 happy path | + 1-2 边界 | + 错误路径 |
| **D4. 边界/错误处理** | 未处理 | 部分处理 | 关键边界处理 | 显式 + 注释了为什么 |
| **D5. 不越界** | 大量无关改动 | 1-2 处可疑 | 紧贴 brief | + 删了死代码 |
| **D6. 注释克制** | 过度/废话注释 | 略多 | 只在 why 不明显处加 | 零废话注释 |
| **D7. 安全性** | 注入/越权/明文密钥 | 缺输入校验 | 输入校验 + 边界 OK | + 依赖审过, 无新增漏洞面 |
| **D8. 性能** | 明显 N+1 / O(n²) 误用 | 无意识低效 | 合理实现 | + 注释了复杂度选择 |

## 退回模板 (Codex 03c → OC-impl)

\`\`\`
Verify 不通过. 原因:
- [hard fail 列表 / 或维度低分理由]

修改要求:
1. ...
2. ...
保留: [OC 做对的地方, 显式列出]
轮次: X/3 (超过 3 轮升 Human 决策)
\`\`\`

## 维度低分常见模式速查
(给 Codex 03c 参考, 加快打分)

- D1 fail 信号: 子任务包列了 5 条必做, OC 只实现了 3 条
- D5 fail 信号: 单文件 diff 行数远超合理估计(e.g. 改一个函数动了 100 行)
- D7 fail 信号: SQL 字符串拼接 / 文件路径未规范化 / 硬编码 token
- D8 fail 信号: 循环内 DB 查询 / sync 写文件在 hot path
```

## 8 · 经验回流 main 的协议 (双向 sync)

(沿用 v1 §7, 不变)

### 8.1 finding 命名约定

```
lite/.ai/logs/pending-findings/from-<project>/
├─ starter-v0.X-lite-finding-NN-codex-architect-*.md     ← lite specific
└─ starter-v0.X-lite-finding-NN-oc-review-*.md            ← 通用, sync 候选

ai-collab-starter/.ai/logs/pending-findings/from-lite-<project>/
└─ <symlink or copy from lite repo>
```

### 8.2 sync 触发时机

**lite → main**:
- 每个 lite minor release(v0.1, v0.2, ...) 时人工扫 lite findings 是否有通用项
- 通用项 cp 到 main inbox 的 `from-lite-<project>/` 子目录(prefix `from-lite-`)
- main 下次升级 session 时扫到

**main → lite**:
- main MINOR release 后, lite owner 评估是否同步通用改进(非 Claude-specific)
- 通用改进 cp 到 lite repo, 走 lite 升级仪式实施
- Claude-specific 改进(如 claude-review-required frontmatter)lite 跳过

### 8.3 sync 工具(可选)

写 `scripts/lite-main-bidirectional-sync.sh`, 半自动 diff 两个 repo 的 `.ai/prompts/` 并提醒 owner 处理冲突。
v0.1.0 不强求, 等真实有 sync 需求再开。

## 9 · 验收标准 + smoke test

### lite v0.1.0 release 门槛

1. [ ] 4 个新/改 prompt 文件(`02-codex-plan.md` / `03-codex-orchestrate.md` / `03b-opencode-impl.md` / `oc-helper.md`)各跑通一次本机 smoke
2. [ ] 02-codex-plan.md 强约束 7 条全落地, 写一个 mock task brief 验证 alternatives 段不空 + OC delegation candidates 段不空
3. [ ] oc-code-quality-rubric.md 文件存在, Codex 03c prompt 引用了它, 跑 mock 验收能正确给分 (mock: 故意给一份越界的 diff, 看是否 H2/D5 fail)
4. [ ] 04-opencode-review.md "Codex 自审盲点专项检查" 段有可执行 checklist
5. [ ] state.md template 触发来源 lite 3 类逻辑自洽(无 Claude 残留)
6. [ ] lite-upgrade-protocol.md 7-step Human 主导版本完整
7. [ ] CHANGELOG 写明 fork from main v4.0-rc1 + breaking diffs + ACP 否决记录
8. [ ] **共享文件协议 smoke**: 起 T1/T2 两终端, Codex 写一个 req 文件, OC-helper 写一个 out 文件, Codex 读到 → 通过
9. [ ] **完整 epic smoke**: 至少一个 throwaway 项目 init 跑通: Codex 02 → 03a → OC-impl 03b → Codex 03c → OC-review 04 → Human merge (4 终端齐用)
10. [ ] 经验回流协议在 lite-upgrade-protocol.md 引用 §8

### smoke test 顺序

```bash
# 1. clone lite repo
git clone <lite-repo> /tmp/test-lite
cd /tmp/test-lite

# 2. 开 4 终端 (tmux 或 4 个 iTerm tab)
#    T1: codex (主驱动)
#    T2: opencode (OC-helper)
#    T3: opencode (OC-impl)
#    T4: opencode (OC-review)

# 3. 在 T1 Codex 喂 02 prompt: "按 .ai/prompts/02-codex-plan.md 给 'add hello endpoint' 出 task brief"
# 4. Codex 出 brief, Human 看强约束 7 条是否满足 → gate
# 5. Codex 进 03a, 输出 OC-impl 子任务包, Human 复制到 T3
# 6. T3 OC-impl 写代码, 输出 done
# 7. Human 回 T1, Codex 03c 验收, rubric 打分
# 8. 假设通过, Codex 输出 04 启动指令, Human 复制到 T4
# 9. T4 OC-review 三步法, 输出 findings, Human 复制回 T1
# 10. Human gate → merge

# 共享文件 smoke (中间穿插一次):
# Codex 03a 决定走 OC-helper 扫整个 internal/, 写 req-1-1.md
# Human 切 T2 喂 OC-helper prompt, OC-helper 写 out-1-1.md, 报 done
# Human 切回 T1, Codex 读 out-1-1.md
```

## 10 · 工时 + 风险

### 工时

| Phase | 内容 | 工时 |
|-------|------|------|
| 1. lite 文件改造 (§4 表) | 14 个文件按表改 | 1.5 h |
| 2. 02-codex-plan 强约束 + 03 三段式 prompt 详写 | 含 mock task brief 验证 | 45 min |
| 3. oc-code-quality-rubric.md + 03c 验收 prompt | 详写 + 跑 mock 验收 | 30 min |
| 4. 共享文件协议 smoke (req/out 模板 + OC-helper prompt) | 含 T1/T2 两终端跑通 | 20 min |
| 5. 完整 epic smoke (§9.9) | 4 终端齐跑一次 throwaway | 30 min |
| 6. CHANGELOG + commit + tag v0.1.0-lite + push | release | 20 min |
| **总计** | | **~3 h** |

(vs v1 估的 6h, 因删除 1.5h 的 MCP server 实施 + 协议设计本身简化)

### 风险清单

| 风险 | 概率 | 影响 | mitigation |
|------|------|------|-----------|
| Codex 当架构师 alternatives 段质量 | 高 | 中 | force 7 条 + 04 review 严审 + first epic 后人工 sample |
| OC-impl 反复 verify fail (3 轮上限触发) | 中 | 中 | rubric 退回模板要 Codex 显式列"保留"段, 防 OC 推倒重来; 3 轮后 Human 决策三选 |
| OC-review 跟 OC-impl 是同模型, 有共谋盲点 | 中 | 高 | session 强隔离 + "Codex 自审盲点专项 checklist" + Codex 03c 已经先过滤一遍 |
| Human 4 终端管理负担 | 中 | 中 | getting-started 给 tmux/iTerm 模板; OC-helper 默认懒启动(等 Codex 第一次需要再开) |
| lite 跟 main 长期 divergence | 高 | 低 | §8 双向 sync 协议 + 每 minor release 主动扫 |
| 共享文件协议被 epic 间残留污染 | 低 | 低 | epic 结束 Human 手动 `rm -rf .ai/scratch/oc-helper/*`; `.gitignore` 保兜底 |

### Go/No-go 决策点

v2 删除了 v1 的 ACP spike phase, **不再有技术不确定性**(全是 prompt + 文件协议, 没有外部 binary 集成)。
唯一需要 Human 在实施期决策的点:

- Phase 5 完整 epic smoke 跑完, 看 **Codex 02 强约束遵守度 + OC-impl 一次通过率** 是否可接受
  - 若 Codex alternatives 段持续敷衍 → 加强 02 prompt 措辞 + 加 brief 自检 checklist
  - 若 OC-impl 一次通过率 < 50% → 子任务包颗粒度太粗, 调小

## 11 · 下次 session 启动指南 (v4.0-rc1 自演化能力试金石)

### Human 启动新 session 步骤

```bash
# 1. cd 到 starter 仓
cd /Users/qf/Alcedo/code/ai-collab-starter

# 2. 跑 status check(v4.0-rc1 新机制)
bash scripts/starter-status.sh

# 3. 让 Claude(在 main 仓 / 本机)读这份设计文档启动 lite 实施
cat .ai/lite-v0.1.0-design.md | head -80  # 看一眼 §0 变更摘要
```

然后告诉 Claude(任意 Claude session, 不需要带本次对话上下文):

```
请读 ai-collab-starter/.ai/lite-v0.1.0-design.md 全文,
按其中 §10 工时表执行 Phase 1-6, 实施 lite v0.1.0 发布。

注: v1 设计 (.ai/lite-v0.1.0-design-v1-acp-archived.md) 已否决, 不要看。
v2 (本文) 是当前唯一有效设计。

无技术 spike phase (v2 已删除 ACP), 但 Phase 5 跑完后要报 smoke 结果,
Human 决定是否继续 release。
```

### 这个流程本身验证 v4.0-rc1 的什么

- ✅ **跨 session 上下文重建**: 新 session Claude 没有本对话记忆, 但读设计文档能 100% 重建
- ✅ **starter-upgrade-protocol** 没直接用(因为不是 starter 升级, 是新建 lite), 但模式同
- ✅ **finding 双写**: 实施期发现的新 finding 应同时入 lite repo 和 main inbox(prefix `from-lite-`)
- ✅ **Human 决策点显式**: §10 Go/No-go 是 Human escalation 接口
- ✅ **设计文档迭代**: v1 → v2 完整保留(归档 + 顶部 §0 变更摘要), 验证演化追溯能力

### 如果新 session Claude 卡壳

设计文档若有不清楚的地方, 在新 session 内提问, Claude 应能从文档 + main repo 现状 +
v4.0-rc1 协议自答 80%+ 问题。剩 20% 升 Human 决策。

---

## 附录 A · v2 设计讨论要点 (2026-05-16 session)

1. **ACP 否决**: 核实后发现 IBM BeeAI ACP 已 2025-08-27 archived, 合并入 A2A; Codex CLI 不原生支持 ACP; HTTP REST server 与 lite 极简定位矛盾。Human 决策: 出局。
2. **MCP 也出局**: 评估过用 MCP 当替代(原 v1 底座), 但 Human 提议更激进: "还是手动拷贝提示词吧". 采纳, 引出"Human 当 bus + 文件做总线"设计。
3. **OC 升级为写代码主力**: Human 提议"还是想让 OpenCode 写代码, 总要给它机会". 采纳, Codex 改当 lead engineer (拆 + 验), 引出 03 三段式 + rubric.
4. **OC session 隔离粒度**: Human 提问 "每次 OC-impl 都是新会话吗?". 定下"阶段内连续, 阶段间隔离, epic 间清零"。
5. **OC-helper 共享文件协议**: Human 提议"opencode 输出到一个共享文件里". 采纳, 比 chat 复制更适合大结果传输。
6. **触发条件**: 全仓搜索走 OC-helper, 有限范围 Codex 自己 (Human 选 C)。
7. **rubric 维度**: Human 加 D7 安全 + D8 性能, 总分 24, 门槛 16/24, 不分核心/glue。
8. **重试上限**: Human 定 3 轮, 超限升 Human 三选 (a) Codex 接手 (b) OC 第 4 轮 (c) 回 02 重切。

## 附录 B · 不在本 v0.1.0 范围

- 自动重试 / 错误恢复机制(retry 计数自动化)→ v0.2.0
- OC-impl 并行(同 epic 多个子任务包并发 OC 实例)→ v0.3.0
- lite 跨语言 / 跨框架适配验证 → v0.4.0+
- 共享文件协议升级为真正的 IPC(若 Human bus 痛点累积)→ v0.5.0
- 与 main 的实战双向 sync → 等 lite 跑过至少 1 个真 epic 再做

## 附录 C · v1 与 v2 关键设计变更映射 (审计用)

| v1 段 | v1 内容 | v2 处理 |
|-------|--------|---------|
| v1 §3 ACP 技术 spec | MCP stdio + oc-mcp-server + 4 tools | **整段废弃**, 替换为 v2 §3 手动转交协议 |
| v1 §3.3 4 个 MCP tools | oc_scan_files / oc_grep / oc_summarize / oc_review_diff | **概念合并**到 v2 §3.4 OC-helper 共享文件协议(action: grep/scan/summarize)+ v2 §6 OC-impl(替代 oc_review_diff) |
| v1 §4 lite 改造表 | 含 oc-mcp-server/ + .mcp.json | 删, 加 oc-code-quality-rubric.md + oc-helper.md + 03b-opencode-impl.md |
| v1 §5 02 强约束 7 条 | 含 ACP delegation candidates(第 7 条) | 第 7 条改 **OC delegation candidates** (helper + impl 两类), 其余不变 |
| v1 §6 ACP 调用模板 | MCP tool_use 形式 | 删, 用 v2 §6.1 OC-impl 子任务包模板 + v2 §3.4 req/out 文件 |
| v1 §9 工时 | ~6h, 含 Phase 0 ACP spike 1.5h | **~3h**, 删 spike, Phase 名重编 1-6 |
| v1 §9 风险表 | 含 OpenCode CLI MCP 支持 / Codex CLI MCP client 配置 / oc-mcp-server 维护 | 删上 3 条; 新增 "OC-review 与 OC-impl 共谋盲点" / "Human 4 终端管理负担" |
| v1 §10 启动指南 | 让新 session Claude 按 Phase 0-5 跑 | 改 Phase 1-6, 显式声明 v1 archived 不要看 |

---

设计冻结 v2 · 2026-05-16
