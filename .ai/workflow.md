# AI Collaboration Workflow (lite v0.4.0-lite-rc1)

> **lite vs main**: 无 Claude,Codex 当 lead engineer(架构 + 拆任务 + 验收),OC 写代码 + 审 + 信息查询。
> Escalation 接收方是 **Human**,不是 Claude main session。

This workflow turns requirements into reviewed, testable changes while preserving context across long-lived multi-repo development.

## 0. 4 终端拓扑 (session 抽象, 不绑 UI 形态 · v0.4 · F03-self)

> **T1-T4 是 session 抽象**, 不是 4 个物理终端。实际形态见 `.ai/getting-started.md §一 Step 3` (Desktop / tmux / iTerm 三选)。
>
> "T" 是 "Terminal" lite v0.1.0 命名遗留 (作者假设 CLI/TUI), v0.4 起建议读作 **"Track" (轨道)** 更准确: 每个 Track 是一个独立 agent session, 跨 epic 不复用。

### Track ↔ UI 形态对照 (v0.4)

| 抽象 (Track) | Desktop app sessions (推荐) | CLI/TUI |
|-------------|---------------------------|---------|
| T1 (Codex / lead engineer) | Codex Desktop chat 1 | tmux/iTerm pane 1 |
| T2 (OC-helper / 全仓搜索) | OpenCode Desktop chat 1 | pane 2 |
| T3 (OC-impl / 写代码) | OpenCode Desktop chat 2 (独立 session 防自审) | pane 3 |
| T4 (OC-review / 独立审) | OpenCode Desktop chat 3 (独立 session 防自审) | pane 4 |


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
       └────────► ┌─────────────┴──┴─────────────┐
                  │      Human (message bus)     │
                  │ 复制 prompt / 说 "done" / 转交  │
                  └───────────────────────────────┘
```

### Session 隔离规则(强制)

| 场景 | 规则 |
|------|------|
| 一个 epic 内的多轮 03b OC-impl | **同一 session 内继续**(保留 Codex 反馈历史) |
| 一个 epic 内的多轮 04 OC-review | **同一 session 内继续**(review→fix→review 循环) |
| 一个 epic 内 OC-helper 多次查询 | **同一 session 内继续** |
| **03b ↔ 04(不同阶段之间)** | **必须新 session**(防自审盲点) |
| 不同 epic 之间 | 全部新 session(隔离上下文污染) |

一句话:**阶段内连续,阶段间隔离,epic 间清零**。

### git 拓扑维度 (v0.2.0 · F01)

4 终端拓扑只画"信息流", 还有一维**git 拓扑**决定 git 操作 cwd 边界:

| git 拓扑 | 含义 | git 操作 cwd 边界 |
|---------|-----|------------------|
| **单仓** (默认) | 单 `.git`, lite 元数据 + 业务代码同仓 | repo 根目录跑 git, 沿用现有约定 |
| **umbrella + 子 git** | 顶层 `.git` 只追 `.ai/` + `AGENTS.md`, 子目录各有独立 `.git` (e.g. smart-uite 30 子项目 C++ 系统) | umbrella 顶层 git 不追子路径; **任何 git 操作 (log/diff/blame) 必须 cd 进对应子仓**; 顶层 `git log -- Daemon/` 返回空 ≠ Daemon 无 commit |
| **跨仓** | lite 仓 + 业务仓物理分离, env var $COLLAB_ROOT / $REPO_* | 每个 repo 各自 cwd, prompt / req 文件必须显式标 cwd |

→ 详见 `.ai/getting-started.md §一bis · git 拓扑选择` 和 `.ai/prompts/oc-helper.md > git 子操作纪律` 段。

### 阶段流转图 (v0.3.0 加 01-intake 起点 · v0.2.0 · F13)

主线 + 过渡态分支:

```
   ┌──────────────┐   (v0.3 入口 B)
   │ 01-intake    │   Codex Q&A ≤ 5 轮
   │ (可选起点)    │───→ 产 brief 文件 ───┐
   └──────────────┘                       │
                                          ↓
   ┌─────────┐    ┌──────────────┐    ┌──────────────┐
   │ 02-plan │──→│02-plan-refine│──→│03a-decompose │
   └────┬────┘    └──────────────┘    └────┬─────────┘
        │ (无须微 L2 直接)                    │
        └──────────────────────────────────→ │
                                              ↓
                       ┌──────────────┐    ┌──────────────┐
                       │  03a-prep    │←──│03b-impl      │
                       │ (微 L2 补查)  │    └────┬─────────┘
                       └──────┬───────┘         ↓
                              ↓            ┌──────────────┐
                       ┌──────────────┐    │ 03c-verify   │
                       │03a-decompose │←───┤ (3 轮上限)   │
                       └──────────────┘    └────┬─────────┘
                                                 ↓ pass
                                          ┌──────────────┐
                                          │  04-review   │
                                          │ → 04-fix-loop │
                                          └────┬─────────┘
                                               ↓ (无 finding)
                                          ┌──────────────┐
                                          │    merge     │
                                          └──────────────┘
   任意阶段 fail → <stage>-human-gate → human override 三选 (a)(b)(c)
```

阶段枚举值见 `.ai/state.md > Active task.当前阶段` 注释段。

## 1. Requirement (v0.3.0 双入口)

### 入口 A: Human 自写 brief (v0.1 起原入口)

Owner: Human(产品 / 工程 lead)。
Output: Goal / Non-goals / Affected repos / Expected behavior / Constraints / Acceptance criteria。
substantial work 建一份 `.ai/tasks/<date>-<slug>.md`。

### 入口 B: Codex 01-intake (v0.3 新增 · Human 一句话 → Codex 反问 ≤ 5 → brief)

Owner: **Codex** (协助), Human 喂一句话 + 答 ≤ 5 反问。
Output: 同入口 A, 但 brief 文件由 Codex 写 + Q&A 留底。
适用: Human 一句话粗描述 / 类型不明确 / 需求细节没想清。
契约: `.ai/prompts/01-codex-intake.md`。
触发边界: 详见 prompt > §触发边界。

无论入口 A 还是 B, 产出 brief 文件后下一步都是 02 (Codex plan)。

## 2. Plan (Codex)

Owner: **Codex**(替代 main 的 Claude 02-plan 职责)。

Inputs:

- `AGENTS.md`
- `.ai/context.md`
- `.ai/architecture.md`
- task file
- relevant `.ai/decisions.md` entries
- 必要时让 OC-helper 跑全仓 grep / scan(走 `.ai/scratch/oc-helper/req-*.md`)

Output(按 `.ai/prompts/02-codex-plan.md` 强约束 7 条):

- Decision(唯一具体选择,不写「或」)
- Rationale
- **Alternatives considered**(≥ 2 个被拒方案 + 具体被拒理由)
- **Data Contract L1-L5 分级**(按项目语言酌情)
- Compatibility and rollout
- **Negative consequences**(≥ 1 项,不可空)
- **Pre-decisions ≥ 3 条**(frontmatter 锁定,实施期不许翻案)
- Implementation slices(paths 二组分:核心 / 连带)
- **OC delegation candidates** 段(helper 任务 + OC-impl 子任务包预告)
- Required tests
- Review focus
- Decision record(ADR-YYYYMMDD-NN)

Record accepted decisions in `.ai/decisions.md`.

### Codex 不写代码

lite 中 Codex **不写业务代码**,产物是 task brief + 03a 阶段的 OC-impl 子任务包。
代码由 OC-impl 写,Codex 拆任务 + 验收。

例外:03b ↔ 03c 走满 3 轮 verify 仍 fail,Human 决策走 (a) Codex 临时接手,此时 Codex
**临时获得本子任务包范围内的写代码权限**,state.md 标 `human-override-codex-fix`。

## 3. Implementation (Codex 03 三段式)

### 3a. 拆任务(Codex)

Owner: Codex(T1)。

Codex 把 brief 拆成 N 个 **OC-impl 子任务包**(每包 ≤ 1 个 slice,通常 30 min 内完成)。
模板见 `.ai/prompts/03-codex-orchestrate.md > 03a 段` 或本 workflow §6.1。

每个子任务包必含:
- 上下文(brief 路径 + pre-decisions 摘要 + paths 二组分)
- 实施要求(必做 / 测试 / 风格 / 禁止)
- 验收标准(走 `.ai/oc-code-quality-rubric.md`,门槛 ≥ 16/24)
- 完成产出格式("done, 见 git diff")

### 3b. 写代码(OC-impl)

Owner: **OC-impl**(T3)。

Inputs:

- 子任务包(Codex 03a 输出,Human 复制到 T3)
- 子任务包里引用的 brief 段落(OC-impl session **不**带完整 brief 上下文)
- 明确的 paths 二组分(核心 / 允许连带)
- 明确的测试命令

Output:

- 最小 patch(动 git working tree)
- 跑通子任务包要求的测试命令
- 输出 "done, 见 git diff"(不要总结自己改了什么,Codex 自己看 diff)

Rules:

- 实施一个子任务包一次。
- **严禁**翻案 brief frontmatter 的 pre-decisions D1-Dn 任一条。
- **严禁**动子任务包未列的 paths(核心 / 连带都不行)。
- 不"顺手"清理相邻代码。
- 单文件 diff > 200 行 → 停下来问(除非子任务包预声明)。
- 完成后**不**自己进 03c,等 Codex 拿 git diff 验收。

### 3c. 验收(Codex)

Owner: Codex(T1,与 03a 同 session)。

Codex 拿 `git diff` + brief + 子任务包,用 `.ai/oc-code-quality-rubric.md` 打分:

1. **硬门槛 H1-H5** 逐条 check(任一 fail → 直接退回 OC-impl,不打分)
2. **维度 D1-D8** 逐项打分,总分 **≥ 16/24** 通过
3. 通过 → state.md 进 04;退回 → 输出退回模板喂回 OC-impl

#### 退回模板

```
Verify 不通过. 原因:
- [hard fail 列表 / 或维度低分理由]

修改要求:
1. ...
2. ...
保留: [OC 做对的地方, 显式列出, 避免它推倒重来]

轮次: X/3
- 若 X<3: 请按上述修改, 提交后重新 done
- 若 X=3: 不要再改了, 请输出"达到 3 轮上限, 升 Human 决策"
```

#### 重试上限

- **03b ↔ 03c 最多 3 轮**,第 3 轮 verify 仍 fail → 升 Human(lite 触发来源 H)
- Human 决策三选:
  - (a) Codex 接手改(临时获得本子任务包写权限,state.md 标 `human-override-codex-fix`)
  - (b) OC 再试第 4 轮(Human 给 OC 新 hint)
  - (c) 回到 02 重新拆任务(brief 本身可能有问题)

## 4. Review (OC-review)

Owner: **OC-review**(T4,**必须**与 OC-impl 不同 session,防自审盲点)。

按 `.ai/prompts/04-opencode-review.md` 三步法:

### 4.1 Scope 验证

对照 task 文件「核心改动 paths」+「连带改动 paths」核对 commit 实际改动:
- 严格在范围内 → 正常进入第二步
- 超出范围 → 翻 status 为 `escalated`,state.md `Next step` 指向 Human(lite 触发源 C)

### 4.2 Architecture / pre-decisions 对齐

对照 brief frontmatter `pre-decisions` + 已 accepted ADR:
- 实现兑现 pre-decisions / ADR → 正常进入第三步
- 偏离 pre-decisions 但未在新 ADR 记录 → escalation(C)
- 形式上用了 pre-decisions 选择但价值吃光 → escalation(C)

### 4.3 Quality + Codex 自审盲点专项

通用 quality:correctness / missing tests / docs drift / style / N+1 / 资源关闭等。

**lite 新增 · Codex 自审盲点专项 checklist**(因 Codex 03c 是自审,需 OC-review 独立 cross-check):

- [ ] 子任务包颗粒度合理(不超 1 slice;子任务步骤 ≤ 6 条)
- [ ] Codex 03c 验收时所有 rubric 维度都给了具体证据,不是「OK」一字过
- [ ] OC-impl 的实施确实在子任务包"必做"清单 100% 覆盖范围内
- [ ] pre-decisions 没被 OC-impl 翻案(grep diff 中是否动了 frontmatter 提到的字段 / 接口 / 选择)
- [ ] 03c 退回模板触发的轮次(若 > 1)有保留段,OC-impl 不是每轮推倒重来

输出落 `.ai/review.md`。

### 4.4 Escalation 路径(lite)

OC-review 在以下任一情况下**必须** escalate 给 **Human**(state.md `Next step.Agent = Human`):

1. Scope-deviation 检出(修改文件数 / diff 行数明显超出 子任务包描述)
2. 架构敏感改动(注解 / 类继承 / 配置结构 / SPI 接口签名变更)
3. pre-decisions 偏离但 commit 中未新增对应 ADR
4. 跨仓 / 跨服务协议改动
5. 失败模式 / 并发 / 生命周期复杂度高的改动
6. 安全 / rollout 风险
7. Codex 自审盲点专项 checklist 命中

Human 介入时**不**作为独立 step——审视结果由 Human 直接决定:接受 / 退回 / 升级问题到 02 重切。

### 4.5 不允许"内联跑了但没记录"

无论 OC-review 走完三步法还是中途 escalate,所有 review 输出都必须落到 `.ai/review.md`。
聊天里口头说"我审了"不算 review;review.md 上没有对应段落 = review 未发生。

## 5. Fix (OC-impl 或 Codex 接手)

Owner: 默认 OC-impl(T3,同 epic 内同 session 继续);触发上限 (a) 时 Codex 临时接手。

Inputs:

- OC-review accepted findings
- 改动文件清单
- 失败测试 / CI log

Output:

- Focused fixes
- Re-run tests
- Updated review status

Rule: OC-impl 只修 accepted findings。新架构问题回 02 重切(不让 OC-impl 自由发挥)。

## 6. Merge

Owner: **Human**(repo maintainer 角色,assisted by Codex 出 commit 摘要)。

Checklist:

- (若适用)GitNexus `detect-changes` 在改动 repo 跑过
- 子任务包指定的测试都跑过 or 已记录跳过理由
- `.ai/progress.md` 含改动文件与验证
- `.ai/review.md` 没未解决的 blocking findings
- Commit scope 小且 repo-specific
- PR 描述含 behavior / tests / risks / rollback notes

## 6.1 OC-impl 子任务包模板(03a 输出)

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
- 单文件 diff > 200 行 (超了停下来问)

## 验收标准 (Codex 03c 会用 rubric 打分)
见 `.ai/oc-code-quality-rubric.md`, 总分 ≥ 16/24 通过, 否则退回。

## 完成产出
- git working tree 已改, 等 Codex 03c 验收
- 输出 "done, 见 git diff" 即可
```

## 9. Epic closeout (收口 · v0.4 新增 · F01-self)

epic merge 完成后, Human (或喂 `.ai/prompts/09-codex-closeout.md` 给 Codex 协助) 跑下列 checklist。
不收口 = 下个 epic 启动时 context 污染 (旧 epic state.md 残留 / scratch 残留干扰新 task)。

### 🗑️ 清 (per-epic ephemeral)

| 文件/目录 | 操作 |
|----------|-----|
| `.ai/state.md > Active task` 段 | 全字段 → NONE; 终端布局 → T1-T4 "空闲" |
| `.ai/state.md > Last completed step` 段 | 全字段 → NONE |
| `.ai/state.md > Next step` 段 | 全字段 → NONE, 可粘贴 prompt body → 单行 `NONE` |
| `.ai/state.md > Blockers` | → "无" |
| `.ai/state.md > Notes` 段 | **保留** epic merge commit + outcome + long-term follow-up; **清掉** epic 内临时上下文 (working state) + 已失效路径引用 (scratch/*) |
| `.ai/scratch/oc-helper/req-<epic>-*.md` | 选项 A 直接 rm / **选项 B (默认)** 先 cp 到 `.ai/logs/archived/<epic-id>/scratch/` 再 rm |
| `.ai/scratch/oc-helper/out-<epic>-*.md` | 同上 |
| `.ai/scratch/oc-helper/gitnexus-<epic>-*.md` | 同上 (v0.2 F04 双路并行产物) |
| `.ai/scratch/oc-impl-package-<epic>-*.md` | 同上 (v0.2 F14 落档纪律) |

**保留** state.md 静态结构: 字段完整性硬约束段 / 维护规则段 / Pattern A/B 安全栏段 / multi-line HTML 注释段闭合 (v0.4 F06-self 硬约束)。

### 📌 留 (持久 / 审计追溯)

| 文件 | 收口操作 |
|------|---------|
| `.ai/progress.md` | append `## <epic-id> · DONE` 段 (含 merge commit / 流转 / follow-up / framework finding 产出 / 强约束生效清单) |
| `.ai/decisions.md` | 不动, ADR 永久保留 |
| `.ai/review.md` | RV finding status 翻 `verified` (Human accepted + verifier 签字) 或 `closed` (defer not addressed); 不删行; defer → Human 的标 `→ Human` 保留 open + 显式 reason |
| `.ai/architecture.md` / `.ai/context.md` | 不动 (本 epic 引入 architecture 变化才更新) |
| `.ai/tasks/<完成 task>.md` | 默认保留 (epic 文档); ≥ 1 月后归档可 mv 到 `.ai/logs/archived/<epic-id>/` |
| `AGENTS.md > Known Sharp Edges` | 评估 dogfood 触发的工具/环境/平台特定经验, append 一条 (lite framework finding 不放这里, 落 inbox) |
| `.ai/logs/pending-findings/from-self/` 或 `from-<project>/` | append 新 finding (getting-started §〇 双写约定), 不清 |

### 可选清理

- T1-T4 chat sessions: 本 epic 用完关掉, 下个 epic 开**全新** chat session (workflow §0 "epic 间清零" 强约束)
- Codex Desktop / OpenCode Desktop chat 历史: 删本 epic session 释放 token context

### 收口验证 (机器化 · 硬门槛)

```bash
EPIC_ID=<your-epic-id>

# 1. state.md 三段已重置 (≥ 14 个 NONE)
grep -c 'NONE' .ai/state.md  # 应 ≥ 14

# 2. state.md HTML 注释段闭合 (v0.4 F06-self 加)
OPEN=$(grep -c '<!--' .ai/state.md)
CLOSE=$(grep -c '\-\->' .ai/state.md)
[ "$OPEN" = "$CLOSE" ] && echo "comments balanced" || echo "FAIL: $OPEN open vs $CLOSE close"

# 3. scratch 清空 (本 epic 残留 = 0)
find .ai/scratch -type f -name "*${EPIC_ID}*" 2>/dev/null | wc -l  # 应 = 0

# 4. progress.md 含 epic DONE 段
grep -q "^## ${EPIC_ID} · DONE" .ai/progress.md && echo "PASS" || echo "FAIL"

# 5. review.md 无 P0/P1 open (P3 defer to Human 例外)
grep -c 'Severity:.*P[01]\b' .ai/review.md  # 配合 Status: open 同行/相邻检查
```

### Codex 09-closeout 协助 (v0.4 新增)

Human 不想手动跑 checklist? 喂 `.ai/prompts/09-codex-closeout.md` 契约给 T1 Codex:

```text
你是 Codex。按 .ai/prompts/09-codex-closeout.md 契约执行 epic 收口.
epic: <epic-id> 完了, merge commit <hash>, outcome: <一句话>.
按 4 步流: Step 1 验证前置条件 → Step 2 清 → Step 3 留 → Step 4 收口验证.
```

Codex 跑完, 5 项机器化 verify 全 PASS 即收口完成。

## 7. Worktree convention(沿用 main)

Skills 和 prompts 可能在隔离的 git worktree 中运行。**所有产出必须显式回流主仓**,否则下一步 Agent 会误以为前一步未执行。

### 7.1 worktree 模式触发条件

- skill 调用时 `isolation=worktree`
- prompt 内显式标"建议 worktree 隔离运行"
- 当前 `pwd` 包含 `.claude/worktrees/`

### 7.2 worktree 收尾约定

worktree 中运行的 Agent 在最后一步必须:

1. **state.md 顶部加警告行**:
   ```
   ⚠️ 产出位于 worktree <name>,需 rsync 回主仓后方可用。
   ```
2. **向 Human 汇报第一条必须是显式回流命令**:
   ```bash
   cd <主仓路径>
   rsync -av --exclude='.git' .claude/worktrees/<name>/.ai/ .ai/
   git status
   git add .ai/ && git commit -m "intake(<epic>): ..."
   ```
3. 不要假设 Human 知道 worktree 存在。

## 8. 共享文件协议 (OC-helper + GitNexus + OC-impl 子任务包)

OC-helper 是**全仓搜索 / scan / summarize** 的辅助角色(T2),走 `.ai/scratch/oc-helper/` 共享文件:

- Codex 写 `req-<epic-id>-<n>.md`(请求)
- OC-helper 读 req,执行,写 `out-<epic-id>-<n>.md`(结果)
- Codex 读 out 继续

**触发边界**:
- ✅ 走 helper: `grep "foo" .` / `scan all internal/` / `summarize whole CHANGELOG.md`
- ❌ Codex 自己:`grep "foo" path/to/specific/file.go` / `read 3 个已知文件`

详细 SOP 见 `.ai/prompts/oc-helper.md` 与 `lite-v0.1.0-design.md` §3.4。

### 8.4 OC-impl 子任务包文件 (v0.2.0 · F14)

```
.ai/scratch/oc-impl-package-<task-id>-<n>.md  ← Codex 03a 写: OC-impl 子任务包正文
```

`.gitignore` 已含 `.ai/scratch/`, 子任务包默认不入版本控制 (临时文件, epic 结束 Human 可清空)。
若需归档审计追溯, epic 收口时 Human 把本轮所有子任务包 cp 到 `.ai/logs/archived/<epic-id>/` 保留。

**双输出强约束**: chat 输出 + 文件落档 1:1 同步 — 见 `.ai/prompts/03-codex-orchestrate.md > 03a 输出哪里`。

### 8.6 L2 摸排双路并行模式 (v0.2.0 · F03 + F04)

适用: bug 复现路径未确认 / 嫌疑符号跨子项目 / 项目 ≥ 50 KLOC

双路:
- **文本级** (OC-helper): 走 `.ai/scratch/oc-helper/req-<bug>-N.md` → `out-<bug>-N.md`
- **符号级** (Codex 自跑 GitNexus): 走 `.ai/scratch/oc-helper/gitnexus-<bug>-N.md`

汇总: Codex 02 finalize brief 时双源对比, 互证发现的强化 Decision, 互斥的标 follow-up。

L1 vs L2 区分:
- **L1**: Bootstrap 阶段一次性项目地图 (getting-started §一 Step 4)
- **L2**: per-task / per-bug 摸排 (本段, 02-codex-plan §6 + §7)

GitNexus 接入见 `.ai/gitnexus-integration.md` (v0.2.0 新文件 · F03)。

## CI/CD Extension

This framework can be extended by adding:

- `.ai/tasks/<task>.md` generated from issue templates
- CI job summary copied into `.ai/logs/` and summarized in `.ai/progress.md`
- OC-review prompt run on changed files in PR
- Human escalation triggered on high-risk labels

(lite 中无 Claude escalation;OC 04 触发 escalation 直接到 Human gate)
