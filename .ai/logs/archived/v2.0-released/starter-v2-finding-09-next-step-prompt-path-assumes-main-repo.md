---
finding: starter-v2-finding-09
slug: next-step-prompt-path-assumes-main-repo
date: 2026-05-13
severity: P1
---

# Finding 09 — state.md 的 Next step「可粘贴 prompt」假设文件在主仓,worktree 模式下路径失效

## 现象

intake 在 worktree(`.claude/worktrees/optimistic-mayer-628cd2/`)里跑完后,
worktree 内的 state.md `Next step.可粘贴 prompt` 字段写道:

```text
必读输入(按顺序):
1. AGENTS.md
2. .ai/context.md
3. .ai/tasks/E1-mvp-t1-single-channel.md
4. .ai/decisions.md(含 ADR-20260513-01 MyBatis 选型)
```

这些路径默认以**主仓根目录**为锚点。

但产出当前都在 worktree 子目录里,**主仓根目录下还没有**
`.ai/tasks/E1-mvp-t1-single-channel.md` 这个文件
(它在 `.claude/worktrees/optimistic-mayer-628cd2/.ai/tasks/` 下)。

如果用户直接把这段 prompt 复制到一个新的、cwd 在**主仓根**的 Claude session,
Claude 会:
1. 读 `.ai/context.md` ✓ (主仓有)
2. 读 `.ai/tasks/E1-mvp-t1-single-channel.md` ✗ (主仓没有 → file not found)
3. 读 `.ai/decisions.md` → 读到的是主仓空模板,**不是 ADR-1 那版**

## 影响

- **下一步流程直接卡住或读到过时数据**:
  - 卡住版:Claude 报 file not found,等用户解决
  - 更糟版:Claude 读了主仓空 decisions.md(无 ADR-1)就开始编 plan,
    自行决定一个不同的 ORM(比如 JPA),与已落 worktree 的 ADR-1 冲突
- **可粘贴 prompt 的可信度受损**:用户被教育"state.md 的 prompt 可直接粘",
  但隐含前提是"产出已在主仓",这个前提 worktree 模式下不成立
- 与 Finding 08 形成**叠加风险**——即使用户记得 rsync 回主仓,
  如果 rsync 之前先粘贴了 prompt,依然出错

## 建议

在 starter 的 `state.md` 模板和所有写 `Next step.可粘贴 prompt` 的 prompt
(intake skill、04-opencode-review 等)加一条**前置 guard**:

```markdown
## Next step

> ⚠️ 粘贴本段 prompt 前的前置检查:
> 1. `git status` 在主仓根,确认 `Next step` 引用的文件已在主仓
> 2. 若文件在 worktree 中,先按"收尾"段指令 rsync 回主仓再粘
```

或更彻底的方案:**state.md 在 worktree 写入版,与主仓写入版用不同的模板**:
- worktree 版:`Next step` 首行必须是"先把本目录产出 rsync 回主仓"
- 主仓版:`Next step` 才是真正的下一步 prompt

这两套模板由 worktree 检测自动切换,降低用户记忆负担。

## 严重度

P1 — 与 Finding 08 互锁;单独看每条都"用户多操作一步就好",合起来是
**全链路静默错误传播路径**:产出未回流 → 主仓干净 → 用户以为没出错 →
直接用 state.md prompt → 读到不一致状态 → 决策被错误信息污染。建议 v2.0 必修,
和 08 一起作为"worktree 模式专项加固"打包升级。
