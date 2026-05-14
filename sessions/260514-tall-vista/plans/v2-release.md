# Plan: ai-collab-starter v2.0.0 Release

## Actions
1. **`git add .`** — stage all changes (11 modified/deleted + untracked files)
2. **`git commit`** — commit with message:
   ```
   release(v2.0.0): 16 findings from PaymentRecon E1 + 删除 05-claude-review

   详见 CHANGELOG.md.
   基于 ai-collab-starter v1.0 在异构 Java/Spring Boot/PostgreSQL 项目上的
   完整 4-slice epic 实战,沉淀 19 finding,16 必修已实施.
   Breaking change: 删除 .ai/prompts/05-claude-review.md(并入 04 escalation).
   ```
3. **`git tag v2.0.0`** — create annotated tag

## Impact
- 10 modified files + 1 deleted + ~8 untracked files staged
- Breaking change documented: `05-claude-review.md` 删除
- Tag `v2.0.0` created on the release commit
