# ai-collab-starter-lite v0.1.0 设计文档(ACP 含)

> **状态**: design freeze · 2026-05-15
> **下次 session 启动指南**: 见末尾 §10
> **预计实施工时**: 4-6 h(下次新鲜 session 推荐)
> **作者**: Claude(本 session)
> **触发来源**: Human 提议 "切独立分支跑 Codex+OC, Codex 脑力 OC 体力"

---

## 1 · 项目定位

`ai-collab-starter-lite`(下称 **lite**) 是 `ai-collab-starter`(下称 **main**) 的独立分支变体, **2 Agent + 1 Human** 协同框架, 适配以下场景:

- 没有 Claude API 预算 / 配额受限
- 隐私敏感, 需 air-gapped(Codex CLI + OpenCode 走 local 模型)
- 个人 / 小团队项目, 不需要 Opus 级架构 LLM
- **Codex 脑力 + OC 体力**的实验范式探索

| 角色 | 模型示例 | $/MTok(in/out) | 职责 |
|------|---------|---------------|------|
| **Codex**(脑力) | GPT-5.5(or Anthropic 系类比) | $3 / $15 | 02 架构 + 03 实施 + 调度 OC |
| **OC**(体力 + 审视) | DeepSeek-V4-Pro / 国产 | $0.3 / $1.5 | 04 review 独立 + 受 Codex 调度做 scan/grep/总结 |
| **Human** | — | — | escalation 接收方 + 升级决策 |

**单 step 成本估算**(详见 main session 讨论):
- Codex 02(thinking): ~$0.105
- Codex 03(implement + ACP dispatch): ~$0.14
- OC 04(独立审): ~$0.0084
- **每 slice 总: ~$0.23** (vs main ~$0.35, 节省 34%)

## 2 · 与 main 的关系

`lite` 是 **独立产品线**(独立 SemVer, 独立 CHANGELOG), 不是 main 的 branch。
两者通过 **双向 finding sync 协议** 共享演化经验(详见 §7)。

| 维度 | main(v4.0-rc1+) | lite(v0.1.0+) |
|------|----------|---------|
| Agent 角色 | Claude(架构) + Codex(实施) + OC(审) | Codex(架构+实施+调度) + OC(被调度+审) |
| 02-plan owner | Claude(02-claude-plan.md) | Codex(02-codex-plan.md) |
| 04-review owner | OC(同) | OC(同, 但 review 强约束更严, 防 Codex 自审盲点) |
| Escalation 接收方 | Claude main session | Human |
| 跨 Agent 通信 | 无(各自独立 prompt) | **ACP via MCP**(Codex client → OC server) |
| SemVer | 独立 | 独立 |
| 升级仪式 | starter-upgrade-protocol.md(Claude 主导) | lite-upgrade-protocol.md(Human 主导, OC 辅助) |

## 3 · ACP 技术 spec

### 3.1 协议选型

**MCP(Model Context Protocol, Anthropic 主导, 已成业界标准)** 作为 ACP 实现底座。

**核实结果**(本 session 已 webfetch 验证, 2026-05-15):
- Codex CLI 支持 MCP, 既能当 server 也能当 client(`openai.com/codex/mcp`)
- OpenCode CLI 业内多数兼容 MCP(需本机验证一次)

### 3.2 拓扑

```
┌──────────────────┐       MCP        ┌──────────────────┐
│ Codex CLI        │ ─── stdio/HTTP ─→│ oc-mcp-server    │
│ (MCP client)     │ ←─── tool result ─│ (wraps OpenCode) │
│                  │                  │                  │
│ - 02 架构        │                  │ - exec 子任务    │
│ - 03 实施        │                  │ - 返回结构化 result│
│ - 主决策         │                  │                  │
└──────────────────┘                  └──────────────────┘
                                                │
                                                ▼
                                       ┌──────────────────┐
                                       │ opencode CLI     │
                                       │ (DeepSeek-V4-Pro)│
                                       └──────────────────┘
```

### 3.3 oc-mcp-server 接口设计

OC 暴露给 Codex 的 4 个工具(MCP tools):

#### `oc_scan_files`

```json
{
  "name": "oc_scan_files",
  "description": "Scan a directory or glob pattern, return file list + brief summary of each",
  "input_schema": {
    "path": "string (directory or glob)",
    "summary_per_file": "boolean (default false)",
    "max_files": "int (default 50)"
  },
  "output": "{ files: [{path, size, summary?}], total_count }"
}
```

#### `oc_grep`

```json
{
  "name": "oc_grep",
  "description": "Search a pattern across files, return matches with context",
  "input_schema": {
    "pattern": "string (regex or fixed)",
    "path": "string (where to search)",
    "case_insensitive": "boolean",
    "context_lines": "int (default 2)"
  },
  "output": "{ matches: [{file, line, snippet}], total_count }"
}
```

#### `oc_summarize`

```json
{
  "name": "oc_summarize",
  "description": "Read a file (or section) and return a concise summary",
  "input_schema": {
    "file": "string (path)",
    "line_range": "string (e.g. '1-100', optional)",
    "focus": "string (what to emphasize, optional)"
  },
  "output": "{ summary: string, key_symbols: [string], line_count: int }"
}
```

#### `oc_review_diff`

```json
{
  "name": "oc_review_diff",
  "description": "Given a git diff, do a low-cost review pass (style/scope/obvious bugs)",
  "input_schema": {
    "diff_text": "string (git diff output)",
    "task_brief_path": "string (for scope check)"
  },
  "output": "{ findings: [{file, line, severity, msg}], summary: string }"
}
```

### 3.4 实施路径

oc-mcp-server 用 TypeScript(MCP SDK 最完整)或 Python(MCP SDK 也可)写一个 stdio MCP server, 约 200-300 行代码。
每个 tool 函数内部:
1. 构造 OpenCode prompt(包装 user 意图为 oc CLI 可消费形式)
2. exec `opencode --print --quiet ...` 或等价 API
3. parse OC 输出, 转换为 MCP 工具返回结构

**关键风险**: opencode CLI 输出格式可能不够稳定, 需 parser robust。

## 4 · lite 分支文件改造清单

从 main v4.0-rc1 fork 后, 必改文件:

| 文件 | 改动 | 工时 |
|------|------|------|
| `.ai/prompts/02-claude-plan.md` | **删除**, 替换为 `02-codex-plan.md`(详见 §5) | 50 min |
| `.ai/prompts/03-codex-implement.md` | 加 "ACP delegate 时机" 段, 列何时该调 oc_scan/oc_grep | 20 min |
| `.ai/prompts/04-opencode-review.md` | escalation 路径: Claude → Human; 三步法新增 "Codex 自审盲点专项检查"(catch Codex 架构 fail mode) | 30 min |
| `.ai/state.md`(template) | 删校验注释中 Claude 相关项; 触发来源 v4.0 4 类 → lite 3 类(A 改为 Codex 02 预声明, 删 Claude path) | 15 min |
| `.ai/workflow.md` | §3 架构 owner 改 Codex; §5 escalation 改 Human; 整体术语换 Codex+OC+Human | 20 min |
| `.ai/starter-upgrade-protocol.md` → `lite-upgrade-protocol.md` | 7-step 中 Claude 步骤改 Codex + Human; 升级仪式由 Human 主导 | 30 min |
| `.ai/getting-started.md` | §〇 新 session 启动检查清单中, Claude 主动提醒改为 Human 看 status report | 15 min |
| `AGENTS.md` | 重写: Codex 双岗 + OC 体力 + Human 决策; ACP 调度模式 | 30 min |
| `README.md` | 顶部加 "lite vs main" 段; 用户选 brand 时的决策矩阵 | 15 min |
| `CHANGELOG.md` | 起始 v0.1.0 段, 写明 fork from main v4.0-rc1 + 关键差异 | 15 min |
| `VERSION` | `v0.1.0-lite` | 1 min |
| **新增** `scripts/oc-mcp-server/` | TypeScript MCP server 包装 OC(详见 §3) | 1.5 h |
| **新增** `.claude/.mcp.json` / `codex-config.json` | 注册 oc-mcp-server | 10 min |

总工时: **约 4-6 h**

## 5 · 02-codex-plan.md 强约束设计

Codex 自然倾向"看到一种实现方式就走那条", 缺乏 trade-off 分析。`02-codex-plan.md` 必须**反 Codex 直觉**, force 7 件事:

### 强制条款(草稿示意)

```markdown
# Prompt: Codex 架构与切片(lite v0.1.0)

## 角色

你是 Codex, 在 lite 分支承担 Claude 在 main 中的 02-plan 职责。
你天生擅长生成代码, 但**不擅长做 trade-off 决策**。本 prompt 强制你 force 这件事。

## 强约束 7 条(任一不满足 → task brief 视为 invalid, 强制返工)

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
- 实施期 Codex 03 不允许翻案 D1-Dn 任何一条

### 5. Paths 二组分(核心 / 连带), 与 main 同
(沿用 main v4.0-rc1 02-claude-plan.md 的 paths 二组分原则)

### 6. 锁定符号名前 grep 同包预检
(沿用 main Finding #22 修复, 见 02-claude-plan.md 同段)

### 7. ACP delegation 候选清单
- 在 brief 末尾标 "ACP delegate candidates": 哪些 03 实施期的步骤会调 OC
- 典型: "Codex 03 时调 oc_scan_files 扫 internal/ 目录定位现有 Mapper 实现"
- 这一段让 OC 04 review 时能预期 ACP 调用频率, 反查异常

## 输出格式
(沿用 main 02-claude-plan.md 同结构, 加 pre-decisions frontmatter + ACP delegation 段)

## 收尾
- state.md `Next step.Agent = Codex`(进 03-implement)
- task frontmatter 加 `claude-review-required: false`(lite 无 Claude)
- 触发源: 默认 normal; 若 Codex 自觉本 task 超能力 → frontmatter 加 `human-escalation-suggested: true`
```

## 6 · Codex 03-implement ACP 调用模板

Codex 03 prompt 加新段:

```markdown
## ACP delegate 时机(lite v0.1.0)

实施期遇到以下场景, **必须**调 OC 子工具(经济 + 速度), 不要自己读:

| 场景 | 调 OC 工具 | 例 |
|------|----------|-----|
| 需读 > 5 个文件了解某模块 | `oc_scan_files` | "扫 internal/store/ 看现有 mapper 模式" |
| 全仓 grep 某符号 | `oc_grep` | "找 uploadFile 所有调用点" |
| 总结一个大文件 | `oc_summarize` | "总结 release.go L500-700 做什么" |
| 实施完想自审一遍 | `oc_review_diff` | "对照 task brief, 看本次 diff 是否越界" |

**禁止**让 OC 直接生成业务代码 —— OC 只做 read-heavy 工作, 写代码仍由 Codex 完成。

调用形式(MCP tool):

\`\`\`
<tool_use name="oc_grep">
{
  "pattern": "uploadFile\\s*\\(",
  "path": "internal/",
  "context_lines": 3
}
</tool_use>
\`\`\`

OC 返回结果作为 Codex 03 上下文继续推进。
```

## 7 · 经验回流 main 的协议(双向 sync)

### 7.1 finding 命名约定

```
lite/.ai/logs/pending-findings/from-<project>/
├─ starter-v0.X-lite-finding-NN-codex-architect-*.md     ← lite specific
└─ starter-v0.X-lite-finding-NN-oc-review-*.md            ← 通用, sync 候选

ai-collab-starter/.ai/logs/pending-findings/from-lite-<project>/
└─ <symlink or copy from lite repo>
```

### 7.2 sync 触发时机

**lite → main**:
- 每个 lite minor release(v0.1, v0.2, ...) 时人工扫 lite findings 是否有通用项
- 通用项 cp 到 main inbox 的 `from-lite-<project>/` 子目录(prefix `from-lite-`)
- main 下次升级 session 时扫到

**main → lite**:
- main MINOR release 后, lite owner 评估是否同步通用改进(非 Claude-specific)
- 通用改进 cp 到 lite repo, 走 lite 升级仪式实施
- Claude-specific 改进(如 claude-review-required frontmatter)lite 跳过

### 7.3 sync 工具(可选)

写 `scripts/lite-main-bidirectional-sync.sh`, 半自动 diff 两个 repo 的 `.ai/prompts/` 并提醒 owner 处理冲突。
v0.1.0 不强求, 等真实有 sync 需求再开。

## 8 · 验收标准 + smoke test

### lite v0.1.0 release 门槛

1. [ ] oc-mcp-server 跑通本机 smoke: Codex 调 `oc_grep` 返回结果 ≤ 3s
2. [ ] 02-codex-plan.md 强约束 7 条全落地, 写一个 mock task brief 验证 alternatives 段不空
3. [ ] 04-opencode-review.md "Codex 自审盲点专项检查" 段有可执行 checklist
4. [ ] state.md template 触发来源 lite 3 类逻辑自洽(无 Claude 残留)
5. [ ] lite-upgrade-protocol.md 7-step Human 主导版本完整
6. [ ] CHANGELOG 写明 fork from main v4.0-rc1 + breaking diffs
7. [ ] 至少一个 throwaway 项目 init 跑通: Codex 02 → ACP scan → 03 → OC 04 → Human merge
8. [ ] 经验回流协议在 lite-upgrade-protocol.md 引用 §7

### smoke test 顺序

```bash
# 1. clone lite branch
git clone <lite-repo> /tmp/test-lite
cd /tmp/test-lite

# 2. start oc-mcp-server
node scripts/oc-mcp-server/index.js &

# 3. Codex CLI 配置: 注册 oc-mcp-server
codex config set mcp.oc-server '{ "type": "stdio", "command": "node", "args": ["scripts/oc-mcp-server/index.js"] }'

# 4. 跑一个 mock task: 给 Codex 一个 brief, 看它是否调 oc_grep
codex run "按 .ai/prompts/02-codex-plan.md 给 'add hello endpoint' 出 task brief"

# 5. 检查 OC 是否被调用
ps aux | grep opencode  # 应该看到 opencode 实例

# 6. 最后翻 task brief: alternatives 段是否 ≥ 2 + ACP delegate candidates 段是否填
```

## 9 · 工时 + 风险

### 工时

| Phase | 内容 | 工时 |
|-------|------|------|
| 0. ACP 技术 spike | 写 oc-mcp-server + 跑通本机 smoke | 1.5 h |
| 1. lite 文件改造 | 7 文件按 §4 改 | 2 h |
| 2. 02-codex-plan 强约束 prompt | 详写 + mock task brief 验证 | 1 h |
| 3. 经验回流协议 + CHANGELOG | §7 文档化 | 30 min |
| 4. smoke test | §8 全跑一遍 | 30 min |
| 5. commit + tag v0.1.0-lite + push | release | 30 min |
| **总计** | | **~6 h** |

### 风险清单

| 风险 | 概率 | 影响 | mitigation |
|------|------|------|-----------|
| OpenCode CLI 不支持 stdio MCP | 中 | 高 | fallback 用 subprocess + JSON-RPC(§3.1 路径 2), 或先验证再继续 |
| Codex CLI MCP client 配置坑 | 中 | 中 | 先看 `openai.com/codex/mcp` 官方 doc, 不行 fallback 用 shell exec |
| Codex 当架构师 alternatives 段质量 | 高 | 中 | force 7 条 + 04 review 严审 + first epic 后人工 sample |
| oc-mcp-server 维护成本 | 中 | 中 | 用 TypeScript MCP SDK 写, 跟标准走, 别自创协议 |
| lite 跟 main 长期 divergence | 高 | 低 | §7 双向 sync 协议 + 每 minor release 主动扫 |

### Go/No-go 决策点

下次 session 第 0 Phase(ACP spike)1.5 h 后, **必须**判:

- spike 成功(MCP server 跑通 + Codex 能调) → 继续 Phase 1-5
- spike 失败 → fallback 到 "Step 1 无 ACP 版"(参考本 session 之前讨论, 简化为 Codex 双岗 + OC 独立审, 无 ACP)

不要硬推 ACP。

## 10 · 下次 session 启动指南(v4.0-rc1 自演化能力试金石)

### Human 启动新 session 步骤

```bash
# 1. cd 到 starter 仓
cd /Users/qf/Alcedo/code/ai-collab-starter

# 2. 跑 status check(v4.0-rc1 新机制)
bash scripts/starter-status.sh

# 3. 让 Claude(在 main 仓 / 本机)读这份设计文档启动 lite 实施
cat .ai/lite-v0.1.0-design.md | head -50  # 看一眼摘要
```

然后告诉 Claude(任意 Claude session, 不需要带本次对话上下文):

```
请读 ai-collab-starter/.ai/lite-v0.1.0-design.md 全文,
按其中 §9 工时表执行 Phase 0-5, 实施 lite v0.1.0 发布。

第 0 phase 完成后必须报 spike 结果, Human 决定是否继续。
```

### 这个流程本身验证 v4.0-rc1 的什么

- ✅ **跨 session 上下文重建**: 新 session Claude 没有本对话记忆, 但读设计文档能 100% 重建
- ✅ **starter-upgrade-protocol** 没直接用(因为不是 starter 升级, 是新建 lite), 但模式同
- ✅ **finding 双写**: 实施期发现的新 finding 应同时入 lite repo 和 main inbox(prefix `from-lite-`)
- ✅ **Human 决策点显式**: §9 Go/No-go 是 Human escalation 接口

### 如果新 session Claude 卡壳

设计文档若有不清楚的地方, 在新 session 内提问, Claude 应能从文档 + main repo 现状 +
v4.0-rc1 协议自答 80%+ 问题。剩 20% 升 Human 决策。

---

## 附录 A · 与本 session 讨论的对照

本设计文档基于 2026-05-15 main session 跟 Human 的讨论(主要要点):

1. **角色分工**: Codex 脑力 + OC 体力(Human 提议) → 采纳 + 修正(OC 不写代码, 受 Codex 调度做 read-heavy)
2. **ACP 含义**: Human 用术语 "ACP" 指代跨 Agent 调度协议 → 采纳 MCP 作为底层实现
3. **lite 版本号**: v0.1.0-lite 起步 (Human 选 A 独立产品线)
4. **实施节奏**: v0.1.0 直接含 ACP(Human 选 B 跳过 no-ACP 试点)
5. **本 session 不动手**: 因 session 已超长(跨 PaymentRecon E1 + DeviceOps M2-A + starter v2/v3/v4-rc1), Claude 建议设计冻结 + 下次实施

## 附录 B · 不在本 v0.1.0 范围

- ACP 自动重试 / 错误恢复机制 → v0.2.0
- 多个 OC 实例并行调度(Codex 调多个 OC fork) → v0.3.0
- lite 跨语言 / 跨框架适配验证 → v0.4.0+
- 与 main 的实战双向 sync → 等 lite 跑过至少 1 个真 epic 再做

---

设计冻结 · 2026-05-15
