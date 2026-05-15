---
finding: starter-v2-finding-08
slug: worktree-output-not-merged-back
date: 2026-05-13
severity: P1
---

# Finding 08 — /intake skill 在 worktree 隔离模式下产出不回流主仓,易丢失/混淆

## 现象

新 session 执行 `/intake` 时,Agent 启动了 `isolation=worktree` 模式,
所有产出落在 `.claude/worktrees/optimistic-mayer-628cd2/.ai/` 目录下:

```
.claude/worktrees/optimistic-mayer-628cd2/.ai/
├── tasks/E1-mvp-t1-single-channel.md
├── decisions.md            (含 ADR-20260513-01)
├── state.md / progress.md
└── logs/starter-v2-finding-01..06.md
```

而主仓 `/Users/qf/Alcedo/code/payment-recon-demo/.ai/` 在 intake 跑完后**保持原样**:
- `tasks/` 仍只有 `.gitkeep`
- `decisions.md` 还是空模板
- `git status` 完全干净

intake skill / starter prompt 体系均未在收尾阶段:
1. 提示用户产出在 worktree 而非主仓
2. 给出"如何把产出 merge 回主仓"的具体命令
3. 在 state.md 标注"产出位于 worktree X,需手工合并"

## 影响

- **主仓的人误以为 intake 失败**:`git status` 干净,看不到任何变化,
  容易判断"/intake 没执行成功"或"Agent 没落盘"
- **下一步流程会直接断**:state.md 写"下一步喂 `.ai/tasks/E1-*.md` 给 02-claude-plan",
  但这个文件在主仓根本不存在 → 02-claude-plan 启动时报 file not found,需返工
- **多 finding 文件易遗漏**:用户若不知道 worktree 路径,
  06 条 finding 可能全被忽略,starter v2.0 升级清单严重缩水
- **多 session 协同风险**:如果用户在主仓继续做别的工作并 commit,
  之后才发现 worktree 产出未合并,可能产生 merge conflict 或重复劳动

## 建议

在 `.claude/skills/intake/SKILL.md` 收尾段(以及任何使用 worktree 的 prompt)
加入**显式回流指令**:

```markdown
## 收尾(worktree 隔离模式专用)

若本次 intake 运行在 worktree 中(检查 `pwd` 是否含 `.claude/worktrees/`):

1. 在 state.md 顶部加一行警告:
   `⚠️ 产出位于 worktree <name>,需 rsync/cherry-pick 回主仓后方可用。`
2. 在最后给用户的汇报中,**第一条**必须是显式回流命令:
   ```bash
   cd <主仓路径>
   rsync -av --exclude='.git' .claude/worktrees/<name>/.ai/ .ai/
   git status   # 确认产出已出现在主仓
   git add .ai/ && git commit -m "intake(<epic>): ..."
   ```
3. 不要假设用户知道 worktree 存在 —— 把这步当"必读必做"。
```

更进一步,**starter 的 workflow.md 应该明确写出**:
- 哪些 prompt/skill 默认走 worktree(目前隐含,无文档)
- worktree 与主仓的产出回流约定是什么(rsync? cherry-pick? Agent 内置回流?)
- 失败/中断时 worktree 的清理策略

## 严重度

P1 — 明显摩擦,且**可静默丢失产出**(用户不看 worktree 目录就无从知晓有产出)。
本项目元观察 6 条 finding 若没人主动 check worktree,直接归零,
对 starter v2.0 升级是灾难性的信息丢失。建议 v2.0 必修。
