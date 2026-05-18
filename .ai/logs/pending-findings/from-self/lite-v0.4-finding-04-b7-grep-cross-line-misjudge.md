---
finding-id: lite-v0.4-finding-04-b7-grep-cross-line-misjudge
severity: P3
category: prompt + rubric
source-project: lite-self (v0.4.0-lite stable dogfood · smart-uite h5coat-qt5core-missing bug 04-review)
discovered: 2026-05-19
target:
  - .ai/prompts/04-opencode-review.md (3b · B7 grep pattern 修正)
  - .ai/oc-code-quality-rubric.md (B7 验证段同步)
status: pending
related: [F06-self, F02]
---

# Finding F04-v0.5: B7 state.md 字段完整性 grep pattern 跨行误判, 字段实际完整但 grep -c 计数为 1

## 现象

smart-uite v0.4.0-lite stable dogfood (h5coat-qt5core-missing P0 bug 04-review, 2026-05-19 02:50):

OC-review 跑 B7 字段完整性机器化验证:
```bash
grep -c '当前阶段\|Last completed step.Agent\|Last completed step.Step\|Last completed step.产出\|Next step.Prompt 模板\|Next step.触发来源\|Next step.触发条件\|Next step.输入' .ai/state.md
```

**预期 ≥ 8** (8 个核心字段名), **实际 = 1** (仅"当前阶段"匹配)。

原因: state.md 用 markdown header + list item 多行结构, 字段名分两行存在:
```markdown
## Last completed step

- Agent: OC-review
- Step: 04-review-1
- 产出: .ai/review.md
```

`grep -c 'Last completed step.Agent'` 这种跨行 pattern **无法匹配** (grep 默认行级匹配, `.` 不跨换行)。所以 B7 grep 计数失败, 但**字段实际完整**。

OC-review 在 RV-11 主动指出: "建议 lite v0.5 将 B7 grep pattern 改为逐字段独立 grep 或接受 markdown 多行结构"。

## 影响

- **B7 机器化验证不可信赖**: 当前 grep pattern 永远 fail, 必须 OC-review 人工 fallback 逐项核验, 不达 lite "机器化兜底" 设计意图
- **F06-self B7 扩展 (v0.4 加 HTML 注释闭合 + 13 枚举值完整性) 未触发本 catch**: 这个跨行 pattern 问题是 v0.2 F08 引入 B7 时就有的, F06-self 加 HTML 注释 + 枚举 verify 没覆盖到这条
- **跨 epic 持续**: 上 epic h5coat-start-fails 04 review B7 PASS 但实际 grep 计数也只是 1; 这次 OC-review 主动 catch 才暴露

## 根因

`04-opencode-review.md > 3b · B7 state.md 字段完整性 验证方法` (v0.2 + v0.4 加的版本) 当前 grep:
```bash
grep -c '当前阶段\|Last completed step.Agent\|Last completed step.Step\|Last completed step.产出\|Next step.Prompt 模板\|Next step.触发来源\|Next step.触发条件\|Next step.输入' .ai/state.md
```

错误假设: 字段名"Last completed step.Agent" 在 state.md 同一行存在。
实际: state.md template 是 markdown 风格 (header + bullet list), 字段名跨两行 (header `## Last completed step` + bullet `- Agent: ...`)。

## 提议修复

### 1. **`04-opencode-review.md > 3b · B7`** 验证方法改逐字段独立 grep

```bash
# 字段名应存在 (v0.5 修复 F04-v0.5 · 改为各 line 独立 grep)
# v0.4 旧 pattern 跨行不匹配, 计数永远 ≤ 1
# v0.5 新 pattern 接受 markdown 多行结构

REQUIRED_HEADERS=("## Active task" "## Last completed step" "## Next step")
REQUIRED_FIELDS=("- 当前 task:" "- 当前阶段:" "- 起始时间:" "- Agent:" "- Step:" "- 完成时间:" "- Commit:" "- 产出:" "- Prompt 模板:" "- 触发来源" "- 触发条件" "- 输入:")

MISSING=()
for h in "${REQUIRED_HEADERS[@]}"; do
  grep -q "^$h" .ai/state.md || MISSING+=("header: $h")
done
for f in "${REQUIRED_FIELDS[@]}"; do
  grep -q "^$f" .ai/state.md || MISSING+=("field: $f")
done
[ ${#MISSING[@]} -eq 0 ] && echo "fields complete" || echo "FAIL missing: ${MISSING[*]}"

# 维护规则段 + Pattern A/B (v0.2 F08) — 这个 pattern 是单行的, 仍 OK
grep -c '## 维护规则\|## Human vs Agent\|### Pattern B 的安全栏' .ai/state.md  # 应 = 3

# (v0.4 F06-self) HTML 注释闭合 + (v0.4 F06-self) 阶段枚举完整性 — 仍 OK
# ...略
```

### 2. **`oc-code-quality-rubric.md > B7`** 同步

(B7 在两处, 保持一致)

## SemVer 影响

**PATCH** (现有 B7 grep pattern 修正, 不破坏 v0.4 旧 state.md · 旧 state.md 仍是同一结构, 只是 grep pattern 改成能跨行匹配)。

## 关联

- 与 **F06-self** (v0.4 B7 加 HTML 注释闭合 + 枚举完整性) 同根 — B7 验证完整化系列
- 与 **F02** (state.md 字段漂移) 协同 — 都是 state.md 守约的机器化保障
- 跨 epic: smart-uite 跑 4 个 epic 的 04 review 都没暴露 (因为 OC-review 一般 PASS 不严格 catch 自检 grep 输出), 本 epic OC-review 主动指出
