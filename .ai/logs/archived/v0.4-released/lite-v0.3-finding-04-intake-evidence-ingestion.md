---
finding-id: lite-v0.3-finding-04-intake-evidence-ingestion
severity: P3
category: prompt
source-project: lite-self (v0.3.0-lite-rc1 dogfood · daemon-business-manager-not-started bug intake)
discovered: 2026-05-18
target:
  - .ai/prompts/01-codex-intake.md (新增 Step 1.5 evidence ingestion 段)
status: implemented-in-v0.4.0-lite-rc1
related: [F01-self, F-DOGFOOD-1]
---

# Finding F04-self: 01-codex-intake.md 没明文 force "Step 2 反问前先读 Human 一句话中提供的 evidence 路径", 全靠 Codex 个体行为

## 现象

smart-uite v0.3.0-lite-rc1 第二轮 dogfood (daemon-business-manager-not-started bug):

Human 一句话含具体路径: "你可以看一下 `X:\recardbin\apps\Daemon\bin\logs\Daemon_2026-05-18.txt` 日志, 是我刚运行的"

Codex 实际行为 (按真契约 01-codex-intake.md 跑):
- Step 1 类型识别: "intake type: bug" ✅
- Step 2 反问 Q5: "你的初步 hypothesis 是 'Daemon.ini 路径写错 / 工作目录错 / CreateProcess 路径拼错 / runtime bundle 缺文件' 里的哪一种, 还是暂时未知?"

Q5 列出 **4 个非常具体的 hypothesis 候选** (Daemon.ini 路径 / 工作目录 / CreateProcess 路径 / runtime bundle), 强烈暗示 Codex **主动读了你给的日志文件** 才能列出这些具体猜测 — 否则只能给"未知"。

这是好行为, **但 01-codex-intake.md 契约没明文 force 这条**, 是 Codex 个体行为。

### 第一轮 dogfood 对比 (fallback 到 intake-templates.md §B):
Codex 完全没读日志, Q4 问 "Expected 是否是 Daemon 应拉起哪个进程名和路径?" — 没基于日志收敛, 只能问通用 Expected。

### 第二轮 dogfood (真契约 01-codex-intake.md):
Codex 读了日志, Q5 列具体 hypothesis 候选, 反问质量飞跃。

但**契约没明文要求**, 下次换个 LLM (e.g. 不同国产模型 / 不同 Codex 版本 / 注意力分散的某次执行) 可能漏。

## 影响

- 不严重 (P3 · 这次 Codex 表现好), 但**可预测性差**:
  - 当前依赖 Codex 个体判断 "Human 给了路径要不要主动读"
  - lite 设计哲学 "无协议, 文件即真相" 要求行为可预测, 不应靠 Agent 自主判断关键 quality 项
  - 与 F11 (OC-helper 第三方过滤靠默契) 同形态: F11 修了 OC-helper 默契 → 契约 force, F04-self 应修 01-intake 同样问题
- 长期: 反问质量稳定性 = brief 质量稳定性 = 02 决策质量稳定性, 这条不 force 会渗透下游

## 根因

`01-codex-intake.md > Step 1 类型识别` 当前只说"读一句话, 立即判定类型并显式声明 (chat 第一行)"。
没说 **"若一句话含具体 evidence 路径 (log / commit / file / URL), Step 2 反问前必须主动 Read / Fetch 这些 evidence 作为反问的 grounding"**。

## 证据

- 2026-05-18 第二轮 dogfood 完整 chat 历史 (Codex Q5 列 4 个具体 hypothesis 候选)
- 第一轮 dogfood 对比 (fallback 到老契约, Codex 没读日志, Q4 只能问通用 Expected)
- F-DOGFOOD-4 (v0.3 release 时即兴 audit 记录) 已识别但未落档, 本 finding 是正式落档

## 提议修复

**`01-codex-intake.md`** 在 Step 1 和 Step 2 之间新增 Step 1.5 段:

```markdown
### Step 1.5: Evidence ingestion (v0.4 · F04-self · 反问前必跑)

若 Human 一句话中含**具体 evidence 路径** (任一):
- 文件路径 (含绝对路径 / 相对路径 / Windows 路径 X:\... / Unix 路径 /...)
- log 文件 (.log / .txt 含 "log" 字样)
- commit hash (git commit ID)
- URL (http(s):// 链接)
- 截图路径 (.png / .jpg / 含 "screenshot" 字样)
- 错误码 / stack trace 引用

**必须**:
1. 主动 Read / Fetch / 查看这些 evidence (用相应 tool · Read 文件 / WebFetch URL / Bash git show <commit>)
2. evidence 内容**不在 chat 完整复述** (token 浪费), 只在 chat 摘要 1-2 句: "读了 X 日志, 关键信号: <一句话>"
3. Step 2 反问基于 evidence 收敛, 不再问 evidence 里已经有答案的项 (e.g. 日志已显示 CreateProcess 失败错误码, Q5 hypothesis 候选可直接列具体的, 不再问 "你猜原因")

**禁止**:
- 跳过 evidence 主动 ingest 进 Step 2 (会被 F04-self 兜底 catch)
- 把 evidence 完整复述在 chat (token 浪费 + 干扰 Human 答 Q1-Q5)
- 把 evidence ingestion 当 Q1 反问 ("我能读一下日志吗?" — 已经在 Human 一句话中明确给了路径就是邀请, 不需再问)

#### Evidence ingest 输出格式 (chat)

Step 1 类型识别后, Step 2 反问前, 单段:

```
## evidence ingested (v0.4 · F04-self)
- <evidence-1 path/URL>: <一句话关键信号>
- <evidence-2 path/URL>: <一句话关键信号>
- (若 evidence 不可访问 / 路径错: "<path> not accessible: <reason>", 仍进 Step 2 反问, 把 evidence 不可达列为 Q1)
```

### 触发边界

- 若 Human 一句话**不含**任何 evidence 路径 → 跳过 Step 1.5, 直接 Step 2 反问
- 若 Human 一句话**只含模糊引用** (e.g. "我之前看到一个 log 不记得路径") → Q1 反问 "evidence 路径是?", 不主动猜路径
```

## SemVer 影响

**MINOR** (新增 01-intake 强约束段, 不破坏 v0.3 旧 intake 流 · 旧 intake 没 Step 1.5 仍合法只是不达 v0.4 best practice · evidence 主动 ingest 增量, 不退化)。

## 关联与对照

- 与 **F-DOGFOOD-1** (sync gap) 关联: F-DOGFOOD-1 是 sync 问题不是契约问题已 FIXED; F04-self 是契约本身的 gap
- 与 **F11** (OC-helper 第三方过滤) 同形态: 都是"靠 Agent 默契 → 契约 force" 升级
- 与 **F07** (复现未确认纪律) 协同: F07 force "Q1 必须问 Reproduction 是否已确认", F04-self force "evidence 主动 read"。两者一起把 intake 阶段的反问质量稳定性补全
- 与 **F01-self** (epic-closeout-checklist) 弱关联: 都是 v0.3 release 时识别的 contract 盲区, 一并 v0.4 消化

---

## v0.4.0-lite-rc1 实施记录 (2026-05-18)

- **release**: v0.4.0-lite-rc1
- **触发来源**: lite-self dogfood (smart-uite v0.3.0-lite-rc1 daemon-business-manager-not-started bug epic 跑完 lite v0.3 全流程 + Human 修正 Desktop UI 模型 + 主动询问 closeout 纪律)
- **实施摘要**: 详见 `CHANGELOG.md > [v0.4.0-lite-rc1]` Added/Changed 段, 本 finding (F04-self) 落入对应分组
- **archive 路径**: `.ai/logs/archived/v0.4-released/lite-v0.3-finding-04-intake-evidence-ingestion.md`
