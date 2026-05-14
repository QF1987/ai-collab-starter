---
name: intake
description: Use when the user starts new work and the description is vague — new feature/requirement, bug report, or new project bootstrap. Walks the user through structured questions via AskUserQuestion to produce a complete brief / task file / ADR. Trigger words: "我想做个 X" / "新需求" / "新功能" / "有个 bug" / "新项目" / "开始 X" without enough context. Skip when user already has a complete task file or is mid-flow on an existing task.
---

# Skill: intake

把人参与的关键信息**问出来再写**。避免模型猜偏 → 走错 → 回退。

> 详细问题库与产出模板见 `.ai/intake-templates.md`。本文件是 Codex skill 包装；OpenCode / Codex 直接读 templates 文件即可。

## 何时触发

**触发词（用户说出后建议主动调用本 skill）**：

- 「我想做个新功能 / 新需求」
- 「有个 bug」/ 「报错」/ 「现象」/ 「异常」
- 「新项目」/ 「bootstrap」/ 「初始化」
- 「帮我开始 X」 而 X 描述不清
- 「这是 Tiny / Small / Medium / Large 哪种？」（→ 走 Triage-only 分支）

**不要触发**：

- 用户已有完整 task 文件并在执行中
- 用户描述已包含 brief 五要素（What / Why / Boundaries / Acceptance / Constraints）
- Tiny 改动（< 30 行 typo / 注释 / 命名）
- 用户在追问已答过的细节

## 执行流

### 第 -1 步 · 模式选择（探索式 vs 问答式）

调用 AskUserQuestion 问 Q-1（来自 `.ai/intake-templates.md > 模式选择`）：

```
question: "你的需求处于什么阶段？"
header: "intake mode"
multiSelect: false
options:
  - label: "探索式（推荐）"
    description: "我说 2-3 句大体想法 → agent 替我拼 brief 草稿 → 我审改红字"
  - label: "探索式 · Agent 全权设计（用户授权）"
    description: "我说 1 句大方向 + 明确授权 → agent 决策全部细节 → 我只审 1-2 关键点"
  - label: "问答式（精确版）"
    description: "我心里清楚 → agent 7 题一一问 → 我精确答"
```

#### 探索式 · Agent 全权设计变体（Dogfood #9 修复）

当用户**明确授权** agent 全权决策时（典型话术：「你自己设计就行」/「按经验拍板」/「细节我不管」），skill 走变体流程：

1. agent 收散文（1 句即可）
2. **全部字段填决策**——但每个字段**仍标 `[推断]`** + 一句话理由（透明化，便于人查）
3. **额外保留 1-2 处真正不能瞎拍的字段为 `[待确认]`**——典型：技术栈选型、scope 边界（in/out）、有无写操作
4. 整段口述，用户只审 `[待确认]` 字段，其余视为接受
5. 仍受 3 轮迭代上限约束

**与标准探索式的区别**：

| 维度 | 标准探索式 | Agent 全权设计变体 |
| --- | --- | --- |
| `[推断]` 字段比例 | 30-60% | 80-95% |
| `[待确认]` 字段 | 多个 | 1-2 处必填 |
| 用户审核成本 | 中（逐字段过） | 低（只审 `[待确认]`） |
| 适用阶段 | 需求方向已有但细节未决 | 大方向有 + 信任 agent 经验 |

**警示**：此变体不应作为 agent 越权借口。`[推断]` 标记是不可省的——透明化是用户授权的边界。

#### 探索式工作流（如用户选 A · 推荐）

详细见 `.ai/intake-templates.md > §A 探索式 intake 工作流`。核心 5 步：

1. 让用户输入 1-3 句散文描述
2. **试填全部字段**，每个字段**必须**显式标 `[原话]` / `[推断]` / `[待确认]` 前缀（硬约束）
3. 整段口述给用户审
4. 用户逐字段反馈
5. 迭代（**最多 3 轮**，超过自动转问答式）

**标识纪律**（违反需重写）：

- `[原话]` = 用户散文中直接抽到的内容
- `[推断]` = agent 补的，**必须**一句话说推断理由
- `[待确认]` = 没信息支撑的字段
- 字段开头**禁止**没有这 3 类前缀任一

#### 问答式工作流（如用户选 B）

继续走「第 0 步类型分流」+ 后续问答流。无 agent 推断成分。

### 第 0 步 · 类型分流（探索式 + 问答式 都要）

调用 AskUserQuestion 问 Q0（来自 `.ai/intake-templates.md > 入口分流`）：

```
question: "这次工作是什么类型？"
header: "intake"
multiSelect: false
options:
  - label: "新需求 / 新功能"
    description: "走 task intake 流程"
  - label: "Bug / 现有功能异常"
    description: "走 bug intake 流程"
  - label: "新项目 bootstrap"
    description: "走 bootstrap intake 流程"
  - label: "只想 triage 规模"
    description: "不产出文件，只给路由建议"
```

### 第 1 步 · 按分支问问题

读 `.ai/intake-templates.md` 对应分支（§A / §B / §C / §D）的问题流。

**关键纪律**：

- **每次只问 1 个问题**——不要把多题塞 AskUserQuestion 的多 options 里凑（那是给「单选」用的）。多题分多次调用，每次一个 question。
- **关键题（Q1/Q2/Q3）缺了停下**，不要带病往下走。
- **自适应跳题**：用户在 Q2 选 Tiny / Small 时，跳过 Q4-Q7。
- **Q2.F「不确定规模」**：依次问 F1-F4，按矩阵推断规模，告诉用户结果**并允许覆盖**（"我不同意，应该是 Medium" 时听用户的）。

#### 用什么提问？

- **多选项明确**（如 Severity P0/P1/P2/P3 / 规模 5 档）→ AskUserQuestion + options
- **开放回答**（如「现象一句话」/ 「复现步骤」）→ 让用户直接打字（不用 AskUserQuestion，直接发问后等用户回复）
- **可粘贴文本**（log / stack trace / commit hash）→ 同上，强调「直接粘进来」

### 第 2 步 · 草稿口述（必做）

收齐答案后，**先**用一段精简文本对用户预演关键产出：

```
我会按这些信息生成：
- <文件 1 路径>：<关键内容摘要 3-5 行>
- <文件 2 路径>（如有）：<同上>

下一步建议：<具体哪个 prompt + 路径>

确认无误请回复"go"，需要调整请直接说哪里改。
```

收到 "go" 或等价确认才落盘，否则继续问。

### 第 3 步 · 落盘 + 刷新 state.md（Dogfood #1 强约束）

按 `.ai/intake-templates.md` 对应分支的「产出」段写文件：

- task 文件：`.ai/tasks/<YYYY-MM-DD>-<slug>.md`
- bug 文件：`.ai/tasks/<YYYY-MM-DD>-bug-<slug>.md` + `.ai/review.md` 追加 finding
- bootstrap：`.ai/decisions.md` 追加 ADR + 输出 Codex bootstrap prompt（不直接执行）
- triage-only：不写文件，只口述路由

**同步覆盖刷新 `.ai/state.md`**（与产物文件落盘是同一原子动作，缺一不可）：

- 按 `AGENTS.md > Session State Discipline` 填字段
- `Active task` = task 文件路径，或 `NONE`（探索阶段尚未生成 task 文件时）
- `Last completed step.Agent` = `Codex (intake skill)`
- `Last completed step.Commit` = `n/a`（intake 步骤无代码改动）
- **`Next step` 段必须按 `.ai/prompts/0X-*.md > 下一步提示词 > 统一格式` 的 4 字段输出**（Dogfood #7 修复）：
  - `Agent` / `关键输入`（文件路径列表 ≤ 4 条）/ `Token 预算估计` / `可粘贴 prompt`（≤ 15 行硬上限）
  - 缺字段视为不合规——回头看 8 个 prompt 模板的「下一步提示词 > 统一格式」段
- `Notes` 必带「intake 模式 = 探索式 / 问答式」标记，方便回溯
- **真落盘时 state.md 必须填全所有字段**（Dogfood #7 修复），不要简化省略：
  - 含 `Last completed step` 的 `Step / 完成时间 / 产出` 子字段
  - 含 `Blockers` 段（无阻塞写「无」，不能省略整段）
  - 口述模式可简化，但**真落盘禁止简化**
- 这是 Phase 2 dogfood 抓到的第一个真实漏洞——本 step 落盘但漏刷 state.md，违反整个 prompt 体系

文件落盘后**总是**显式告诉用户：

```
✅ 已落盘：
  - <path 1>
  - <path 2>
  - .ai/state.md（已刷新）

下一步可粘贴的 prompt：
```
<完整 prompt 代码块>
```
```

### 第 4 步 · 不接管

明确告诉用户「intake 任务结束」。不要在同一会话顺手开始 OpenCode 摸排或 Codex 实施——那应该是新会话或显式确认后的继续。intake 的边界就是「把启动信息搞清楚 + 落盘 + 给下一步 prompt + 刷新 state.md」。

**关键纪律**：state.md 未刷新前**不算落盘完成**。即使 brief / task 文件已写好，state 漏刷意味着下次 session 进来看不到下一步——退化为「人脑记忆」而非「文件记忆」。回看 Dogfood #1：intake skill 第一次跑通就栽在这里。

### 第 5 步 · Worktree 模式收尾（v2.0 新增 / Dogfood #08, #09）

若本次 intake 运行在 **isolation=worktree** 模式（检查 `pwd` 是否含 `.Codex/worktrees/`）：

1. **state.md 顶部加警告行**：
   ```
   ⚠️ 产出位于 worktree <name>,需 rsync 回主仓后方可用。
   ```

2. **向用户汇报的第一条必须是显式回流命令**：

   ```bash
   cd <主仓路径>
   rsync -av --exclude='.git' .Codex/worktrees/<worktree-name>/.ai/ .ai/
   git status   # 确认产出已出现在主仓
   git add .ai/ && git commit -m "intake(<epic>): ..."
   ```

3. **state.md `Next step.可粘贴 prompt` 第一行**：必须以 `⚠️ 粘贴前请先 rsync 回主仓` 起头。

4. **不要假设用户知道 worktree 存在**——把"先回流、再粘下一步 prompt"当必读必做步骤；
   主仓 `git status` 干净 ≠ intake 失败,只是产出还没回流。

详见 `.ai/workflow.md §8 Worktree convention`。

不做这一步,18 条 finding 中至少 2 条会重复出现:
- Finding 08：产出静默丢失（用户不知道 worktree 存在）
- Finding 09：state.md `Next step` 引用文件在主仓不存在 → 下一步 Agent file not found

## 反面案例（不要这样做）

❌ 一次问 7 题塞进一个 AskUserQuestion 的 options 里
✅ 分 7 次调用，每次 1 题，让用户从容回答

❌ Q4「范围内 / 范围外」用户写不出来 → 自己补
✅ 提示用户「写不出来说明 scope 还不清，建议先聊清楚再启动」

❌ 收齐答案直接写文件
✅ 先口述关键内容、等用户 say go 再写

❌ 落盘后顺手「我现在就帮你启动 OpenCode 摸排」
✅ 落盘 + 给下一步 prompt + 退出，让用户决定何时启动

## 调用方式

用户输入 `/intake` 时本 skill 启动。
未显式输入但符合触发条件时，Codex 主动建议「需要我用 /intake 把这次任务的关键信息问清楚吗？」并等用户确认。

## 与其他文件关系

- `.ai/intake-templates.md`: 问题库 + 产出模板（**单一来源**，本文件不复制内容）
- `.ai/getting-started.md`: 三类入口的总览文档；本 skill 是其执行工具
- `.ai/prompts/01-08`: intake 落盘后用户启动正式流程的下一步
