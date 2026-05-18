---
finding-id: lite-v0.4-finding-06-state-md-prompt-template-path-no-verify
severity: P3
category: prompt + template
source-project: lite-self (multiple epic 跨 epic 累积观察)
discovered: 2026-05-19
target:
  - .ai/prompts/04-opencode-review.md (收尾必做加 self-verify Prompt 模板路径)
  - .ai/prompts/03-codex-orchestrate.md (03c 收尾同上)
  - .ai/prompts/03b-opencode-impl.md (说明 OC-impl 不刷 state.md, 但若 04-fix-loop 刷需 self-verify)
  - .ai/prompts/09-codex-closeout.md (Step 4 验证段加 Prompt 模板路径检测)
  - .ai/state.md (维护规则段加"Prompt 模板路径必须实际存在")
status: pending
related: [F05-self, F02]
---

# Finding F06-v0.5: state.md `Next step.Prompt 模板` 字段填错路径无 self-verify, 多次 epic 跨 session 跑出笔误

## 现象

跨 epic 累积观察 (3 次实际触发):

### Epic 1: daemon-business-manager-not-started (v0.3 dogfood)

OC-impl 03b 完成时刷 state.md `Next step.Prompt 模板`, 填了**不存在路径**:
```
- Prompt 模板: `.ai/prompts/03c-codex-verify.md` (按 rubric 验收)
```

实际 lite 没有 `03c-codex-verify.md`, 03c verify 段在 `03-codex-orchestrate.md > 03c 验收` 段内。

### Epic 2: dcbusinessmanager-h5coat-start-fails (v0.4 dogfood)

OC-impl / OC-review 多个 step 填 Prompt 模板路径正确 (`.ai/prompts/03b-opencode-impl.md` / `.ai/prompts/04-opencode-review.md`), 但 v0.2 F14 设计意图说 "Prompt 模板 = 子任务包正文" — 多个 epic 不一致。

### Epic 3: h5coat-qt5core-missing (v0.4 stable 后第一个 epic)

OC-review 04-review-1 完成时刷 state.md `Next step.Prompt 模板`, 填:
```
- Prompt 模板: .ai/prompts/03-oc-impl.md
```

实际 lite 没有 `03-oc-impl.md`, 文件名是 `03b-opencode-impl.md`。OC-review 笔误。

## 影响

- **Pattern A 接力质量下降**: Human 看 state.md `Prompt 模板` 字段误以为可粘贴该路径, 实际文件不存在 → 困惑或额外问询
- **降低 lite v0.4 contract 可信度**: state.md 字段值随手填错, 没机器化 verify
- **跨 session 重建质量受损**: state.md 是 Pattern A 真相源, 字段错误的引用应该被 catch
- **不阻塞当前流程** (P3): 因为 `Next step.可粘贴 prompt` 字段含实际 prompt body, OC-impl/OC-review 实际是从 body 复制粘贴, Prompt 模板路径 only 是 reference label
- **但 lite 设计意图**: 字段值应自洽, 不漂移

## 根因

### Gap 1: lite contract 没明示 "Prompt 模板路径必须实际存在"

`state.md > Next step.Prompt 模板` 字段 当前注释:
```
- Prompt 模板: `NONE`
```

没说"必须是实际存在的 .ai/prompts/*.md 文件路径"。

### Gap 2: Codex 03c / OC-review 04 / Codex 09-closeout 收尾必做 没 self-verify

各 prompt 收尾必做都说"刷 state.md", **没说"刷完后 verify Prompt 模板路径文件存在"**。

类似 v0.4 F06-self 加的 B7 self-verify 钩子, 应扩展含 Prompt 模板路径存在性检测。

### Gap 3: B7 字段完整性验证不涉及字段值正确性

B7 检测字段名存在性 + 注释段 / 维护规则段保留 + HTML 注释闭合, **但不检测字段值是否有效路径**。

## 证据

- daemon-business-manager-not-started epic state.md: `Prompt 模板: .ai/prompts/03c-codex-verify.md` (Edit by OC-impl, 不存在文件)
- h5coat-qt5core-missing epic state.md: `Prompt 模板: .ai/prompts/03-oc-impl.md` (Edit by OC-review 04, 不存在文件)
- lite v0.4 stable 实际 prompt 文件清单 (10 个): 01-codex-intake.md, 01-opencode-context.md, 02-codex-plan.md, 03-codex-orchestrate.md, 03b-opencode-impl.md, 04-opencode-review.md, 06-codex-fix.md, 07-opencode-draft.md, 08-codex-audit.md, oc-helper.md, 09-codex-closeout.md (11 个含 v0.4 新增)

## 提议修复

### 1. **各 Agent 收尾必做加 self-verify Prompt 模板路径** (v0.5)

`03-codex-orchestrate.md > 03c 收尾必做`, `04-opencode-review.md > 收尾必做`, `09-codex-closeout.md > Step 4`:

```markdown
#### state.md 刷新后必跑 Prompt 模板路径 self-verify (v0.5 · F06-v0.5)

刷 state.md 后 verify:
\`\`\`bash
PROMPT_TEMPLATE=$(grep '^- Prompt 模板:' .ai/state.md | sed 's/.*: \`\(.*\)\`.*/\1/' | sed 's/.*: //')
[ "$PROMPT_TEMPLATE" = "NONE" ] || [ "$PROMPT_TEMPLATE" = "n/a" ] && echo "OK (intentionally empty)" && exit 0
[ -f "$PROMPT_TEMPLATE" ] && echo "OK ($PROMPT_TEMPLATE exists)" || echo "FAIL: $PROMPT_TEMPLATE not found"
\`\`\`

FAIL → 立即修复 (改对正确路径) + 重 commit, 不算 step 完成。
```

### 2. **`state.md > 维护规则`** 加 "Prompt 模板路径必须实际存在" 硬约束

```markdown
6. (v0.5 · F06-v0.5) `Next step.Prompt 模板` 字段值必须是实际存在的 .ai/prompts/*.md 文件路径,
   或 `NONE` / `n/a` (无下一步 / 不适用). 填错路径会被 04 B7 验证 catch.
```

### 3. **`04-opencode-review.md > 3b · B7` 验证方法** 加 Prompt 模板路径存在性

(集成进 F06-self 已加的 6 项机器化检测, 成为第 7 项)

## SemVer 影响

**PATCH** (新增收尾 self-verify 钩子 + state.md 维护规则 6 + B7 验证扩展 · 不破坏 v0.4 旧 state.md · 旧字段值含不存在路径仍合法但下次 step 完成时被 catch 提示修)。

## 关联

- 与 **F05-self** (子任务包必做 override 03b 契约) 同形态 — 都是 state.md 字段值漂移
- 与 **F06-self** (B7 验证扩展 HTML 注释 + 枚举完整性) 协同 — B7 验证逐步完整化 (从 v0.2 字段名 + 注释段 → v0.4 HTML 闭合 + 枚举 → v0.5 字段值有效性)
- 与 **F04-v0.5** (B7 grep 跨行误判) 同时 v0.5 释放, 一并修 B7 验证逻辑

## 跨 epic 模式记录

| Epic | 触发 step | 错填路径 | 实际应填 |
|------|----------|---------|---------|
| daemon-business-manager-not-started (v0.3) | 03b OC-impl 刷 state.md | `.ai/prompts/03c-codex-verify.md` | `.ai/prompts/03-codex-orchestrate.md` (03c 段) 或 子任务包正文 |
| h5coat-qt5core-missing (v0.4) | 04 OC-review 刷 state.md | `.ai/prompts/03-oc-impl.md` | `.ai/prompts/03b-opencode-impl.md` |

→ 跨 v0.3/v0.4 不同 Agent 都犯, 不是个体行为 → contract gap
