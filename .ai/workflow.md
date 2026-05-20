# AI Collaboration Workflow

This workflow turns requirements into reviewed, testable changes while preserving context across long-lived multi-repo development.

## 1. Requirement

Owner: human or product/engineering lead.

Output:

- Goal
- Non-goals
- Affected repos
- Expected behavior
- Constraints
- Acceptance criteria

For substantial work, create `.ai/tasks/<date>-<slug>.md`.

## 2. Analysis

Owner: Scout.

Inputs:

- `AGENTS.md`
- `.ai/context.md`
- `.ai/architecture.md`
- task file
- scoped paths or symbols

Output:

- Relevant files and symbols
- Existing behavior
- Tests/build commands
- Risks and unknowns
- Suggested Claude questions, if architecture is needed

Rules:

- Analysis must be scoped. Avoid full-repo scans unless justified.

## 3. Architecture

Owner: Claude Code.

Inputs:

- Scout context packet
- task file
- relevant `.ai/decisions.md` entries
- minimal source excerpts or file references

Output:

- Decision
- Alternatives
- Compatibility constraints
- Implementation slices
- Review focus
- Tests and acceptance criteria

Record accepted decisions in `.ai/decisions.md`.

## 4. Implementation

Owner: Impl.

Inputs:

- task file
- accepted architecture decision, if any
- exact repo and path scope
- test commands

Output:

- Minimal code patch
- Updated docs or generated files, if required
- Targeted test results
- Progress entry

Rules:

- Implement one slice at a time.
- Do not expand scope to adjacent cleanup.
- Do not alter architecture without returning to Claude (via 05 escalation).
- For cross-repo protocol changes, update both sides in a planned order.
- **强约束(v2.0)**：03 完成后，state.md 的 `Next step` **必须**指向 `04-review`，不允许直接跳到下一个 slice 的 03。例外仅在 task 文件显式标 `skip-review: true`（< 30 行单文件小补丁）时允许，且需注明豁免理由。

## 5. Review

Owner: Scout (single reviewer; Claude 在 escalation 时介入)。

### 5.1 Scout review 范围

- **Scope 验证**：对照 task 文件「核心改动 paths」+「连带改动 paths」核对 commit 实际改动
  - 严格在范围内 → 正常 review 流程
  - 超出范围 → 翻 status 为 `escalated` 而非 `verified`，state.md `Next step` 指向 Claude（见 5.2 escalation）
- **Architecture 对齐**：对照已 accepted ADR 的 `Decision` 段 + `Data Contract` 段
  - 实现兑现 ADR → 正常 review
  - 偏离 ADR 但未在新 ADR 中记录 → escalation
- **Quality 常规**：correctness / missing tests / docs drift / style consistency / N+1 / 资源关闭等

输出落 `.ai/review.md`。

### 5.2 Escalation 路径（v2.0 替代 v1.0 的 05-claude-review 独立步骤）

Scout 在以下任一情况下**必须** escalate 给 Claude（state.md `Next step.Agent` 写 `Claude`，
不再使用独立的 `05-claude-review.md` prompt——v2.0 已删除该 prompt）：

1. Scope-deviation 检出（修改文件数 / diff 行数明显超出 Expected fix 描述）
2. 架构敏感改动（注解 / 类继承 / 配置结构 / SPI 接口签名变更）
3. ADR 偏离但 commit 中未新增对应 ADR
4. 跨仓 / 跨服务协议改动
5. 失败模式 / 并发 / 生命周期复杂度高的改动
6. 安全 / fleet rollout 风险

Claude 介入时作为 main session 协作者，**不再作为独立 step**——审视结果直接更新 review.md 同一段
（不开新 prompt 文件）。这是 v1.0 → v2.0 的工作流简化（详见 Finding 19 / CHANGELOG）。

### 5.3 不允许"内联跑了但没记录"

无论 Scout review 还是 Claude escalation，所有 review 输出都必须落到 `.ai/review.md`。
聊天里口头说"我审了"不算 review；review.md 上没有对应段落 = review 未发生。

## 6. Fix

Owner: Impl.

Inputs:

- accepted review findings
- changed-file list
- failing tests or CI logs

Output:

- Focused fixes
- Re-run tests
- Updated review status

Rule: Impl fixes approved findings only. New architecture issues return to Claude.

## 7. Merge

Owner: human or repo maintainer, assisted by Impl.

Checklist:

- GitNexus `detect-changes` run in changed repos.
- Targeted tests pass or skipped tests are documented.
- `.ai/progress.md` includes changed files and verification.
- `.ai/review.md` has no unresolved blocking findings.
- Commit scope is small and repo-specific.
- PR description includes behavior, tests, risks and rollback notes.

## 8. Worktree convention（v2.0 新增）

Skills 和 prompts 可能在隔离的 git worktree 中运行（典型：`/intake` skill 的 `isolation=worktree`）。
**所有产出必须显式回流主仓**，否则主仓的人 / 下一步 Agent 会误以为前一步未执行。

### 8.1 worktree 模式触发条件

- skill 调用时 `isolation=worktree`
- prompt 内显式标"建议 worktree 隔离运行"
- 当前 `pwd` 包含 `.claude/worktrees/`

### 8.2 worktree 收尾约定（强约束）

worktree 中运行的 Agent 必须在自己的最后一步：

1. **state.md 顶部加警告行**：
   ```
   ⚠️ 产出位于 worktree <name>，需 rsync 回主仓后方可用。
   ```
2. **向用户汇报的第一条必须是显式回流命令**：
   ```bash
   cd <主仓路径>
   rsync -av --exclude='.git' .claude/worktrees/<name>/.ai/ .ai/
   git status   # 确认产出已进入主仓
   git add .ai/ && git commit -m "intake(<epic>): ..."
   ```
3. **不要假设用户知道 worktree 存在** —— 把"先回流，再粘下一步 prompt"当必读必做步骤。

### 8.3 state.md `Next step` 在 worktree 中的额外纪律

worktree 中刷的 state.md `Next step.可粘贴 prompt`：

- 前置必须有 `⚠️ 粘贴前 rsync 回主仓` 一行
- 引用的文件路径仍用主仓相对路径（rsync 后才有效），不要写 worktree 绝对路径
- 这样下一步 Agent 在主仓 cwd 下粘贴 prompt 时路径自然解析正确

## CI/CD Extension

This framework can be extended by adding:

- `.ai/tasks/<task>.md` generated from issue templates.
- CI job summary copied into `.ai/logs/` and summarized in `.ai/progress.md`.
- Scout review prompt run on changed files in PR.
- Claude escalation triggered on high-risk labels (v1.0 → v2.0: removed independent 05-claude-review step; Claude reviews are now escalations from Scout).
- Impl fix prompt used for failed CI or accepted review findings.
