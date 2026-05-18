---
finding-id: lite-v0.3-finding-06-b7-html-comment-closure-self-verify
severity: P2
category: prompt + rubric
source-project: lite-self (v0.3.0-lite-rc1 dogfood · smart-uite daemon-business-manager-not-started 04 re-review)
discovered: 2026-05-18
target:
  - .ai/prompts/04-opencode-review.md (3b 自审盲点 B7 验证方法加 HTML 注释段闭合检测 + 收尾必做加"刷 state.md 后自跑 B7")
  - .ai/oc-code-quality-rubric.md (B7 验证段同步加)
  - .ai/state.md (维护规则加"刷 state.md 后必须自跑 B7 verify")
  - 新 .ai/scripts/verify-state-md.sh (机器化 B7 一键 verify 脚本)
status: pending
related: [F02, F08]
---

# Finding F06-self: B7 state.md 字段完整性 verify 漏检 HTML 注释段闭合 + Re-review 阶段 OC-review 不自审自刷的 state.md

## 现象

smart-uite v0.3.0-lite-rc1 dogfood (daemon-business-manager-not-started bug, 04 re-review 阶段):

OC-review 在 re-review 完成刷 state.md 时, 把"当前阶段"字段的 multi-line HTML 注释**简化成 single-line**:

**修前 (template 正确结构 · OC-impl 03b 阶段刷的)**:
```markdown
- 当前阶段: 04-fix-loop <!-- 主线阶段 + 过渡态 (v0.2.0 · F13 + v0.3.0 加 01-intake):
     01-intake            · Codex 跑 ≤ 5 轮 Q&A 把一句话 → brief (v0.3 新增 · 可选起点)
     01-intake-done       · Q&A 完成, brief 文件已落 (v0.3 新增)
     ... (12 行枚举值)
     <stage>-human-gate   · 任意阶段 Human 介入决策 (escalation / override, v0.2 新增)
     -->
```

**修后 (OC-review re-review 简化版 · 违约)**:
```markdown
- 当前阶段: merge <!-- 主线阶段 + 过渡态 -->
      01-intake            · Codex 跑 ≤ 5 轮 Q&A 把一句话 → brief (v0.3 新增 · 可选起点)
      ... (12 行枚举值都跑到注释外面成为可见 markdown 文本)
      <stage>-human-gate   · 任意阶段 Human 介入决策 (escalation / override, v0.2 新增)
```

`<!-- 主线阶段 + 过渡态 -->` 第一行就闭合, 下面 12 行枚举**逃出注释段**变成可见 markdown 文本, **F02 字段结构漂移**。

## 根因 (双重盲点)

### 盲点 1: B7 验证方法不全

`04-opencode-review.md > 3b · B7 state.md 字段完整性` (v0.2.0 · F08 加) 当前验证方法:
```bash
grep -c '当前阶段\|Last completed step.Agent\|...' .ai/state.md  # 应 ≥ 8
grep -c '## 维护规则\|## Human vs Agent\|### Pattern B 的安全栏' .ai/state.md  # 应 = 3
wc -l .ai/state.md  # 105 行 ± 5
```

这 3 项**全过** (字段名"当前阶段"还在 / 维护规则段还在 / 总行数 140 接近 template 105), 但**漏检 HTML 注释段闭合**:
- `<!-- ... -->` 的开闭配对没验证
- 注释内枚举是否完整保留没验证
- 这是 B7 验证方法的真实盲区

### 盲点 2: B7 检测对象偏移 — re-review 阶段 OC-review 不自审

B7 是给 04 **主审** 用的, 验证对象是"OC-impl 03b 之前刷的 state.md"。但 **re-review 阶段 OC-review 自刷 state.md 时不跑 B7 self-check**:

- 主审 (04-review-1): 跑 B7 检查 OC-impl 是否漂移 state.md ✅ 设计意图正确
- Re-review (04-review-2): OC-review 自己刷 state.md, **没自跑 B7 检查自己是否漂移** ❌ 设计漏区

本次 dogfood 中 OC-review 主审跑 B7 PASS (因为那时 OC-impl 03b 刷的 state.md 注释段还完整, 实际是被 OC-impl 在 03b 阶段守约写的), 但**自己 re-review 刷时漂移了**, 没人 catch。

## 影响

- **state.md 跨 epic 退化风险**: 本次破坏的注释段如果不修, 会持续到下次 epic (state.md 维护规则 4 "清空 Active / Last / Next, 保留 Notes" 不重写注释段结构)
- **Pattern A 信任度下降**: state.md 是 Human 接力的真相源, 字段结构漂移 = 跨 session 重建质量降级
- **B7 信任度下降**: B7 PASS 不等于 state.md 真完整, 验证方法本身有盲区
- **lite 设计意图 partial 失效**: lite 强调"机器化 verify > 人眼审", B7 是 state.md 质量的机器化保险, 当前保险有漏洞

## 证据

- smart-uite 2026-05-18 17:35:00 04 re-review 刷 state.md 后注释段被破坏 (commit hash 前)
- 我手动 surgical 修复 + commit `bd72452` (smart-uite main 分支): `fix(state.md): restore F02 当前阶段 multi-line 注释段闭合 (re-review violation)`
- 修前 grep 验证 (机器化):
  - `grep -c '<!-- 主线阶段' .ai/state.md` = 1 (注释开头有)
  - `grep -c '^     -->' .ai/state.md` = 0 (注释闭合**没**)
  - 但 v0.3 B7 验证方法**没**用这两个 grep, 漏检
- 修后:
  - `grep -c '<!-- 主线阶段' .ai/state.md` = 1
  - `grep -c '^     -->' .ai/state.md` = 1
  - 配对正确

## 提议修复

### 1. `04-opencode-review.md > 3b · B7` 验证方法扩展

```markdown
- [ ] **B7** (v0.2.0 · F08 + v0.4 · F06-self). state.md 字段完整性: 当前 state.md 按 lite template 完整保留所有字段名 + 维护规则段 + Pattern A/B 段 + **HTML 注释段闭合**
  - 验证方法 (机器化):
    ```bash
    # 字段名应存在 (≥ 8 个核心字段名)
    grep -c '当前阶段\|Agent:\|Step:\|产出:\|Prompt 模板\|触发来源\|触发条件\|输入:' .ai/state.md
    # 维护规则段应存在 (应 = 3)
    grep -c '## 维护规则\|## Human vs Agent\|### Pattern B 的安全栏' .ai/state.md
    # state.md 总行数应接近 template
    wc -l .ai/state.md  # 105-150 范围

    # (v0.4 · F06-self 新增) HTML 注释段闭合检测
    OPEN_COMMENTS=$(grep -c '<!--' .ai/state.md)
    CLOSE_COMMENTS=$(grep -c '\-\->' .ai/state.md)
    [ "$OPEN_COMMENTS" = "$CLOSE_COMMENTS" ] && echo "comments balanced" || echo "FAIL: $OPEN_COMMENTS open vs $CLOSE_COMMENTS close"

    # (v0.4 · F06-self 新增) 关键 multi-line 注释枚举完整性
    # 当前阶段注释段应含 v0.3 全部 13 个枚举值 (含 v0.2 F13 加的 5 个过渡态 + v0.3 加的 01-intake 系列)
    EXPECTED_ENUMS=("01-intake" "01-intake-done" "02-plan" "02-plan-refine" "03a-decompose" "03a-prep" "03b-impl" "03b-retry" "03c-verify" "04-review" "04-fix-loop" "merge" "<stage>-human-gate")
    MISSING=()
    for enum in "${EXPECTED_ENUMS[@]}"; do
      grep -q "$enum" .ai/state.md || MISSING+=("$enum")
    done
    [ ${#MISSING[@]} -eq 0 ] && echo "enums complete" || echo "FAIL missing enums: ${MISSING[*]}"
    ```
  - 命中信号 (v0.4 加):
    - HTML 注释开闭不配对 (本 finding 触发, OC-review re-review 自刷时简化了 multi-line 注释)
    - 枚举值缺失 (Agent 简化 state.md 时把 v0.2/v0.3 加的过渡态枚举删了)
  - 严重度: P2 (lite 系统级风险), 升 Human
```

### 2. `04-opencode-review.md > 收尾必做` 加自审钩子

```markdown
### Review 完成 state.md 刷新后必跑 B7 self-verify (v0.4 · F06-self)

OC-review (无论主审 04-review-1 还是 re-review 04-review-N) 完成刷 state.md 后, **必须自跑 B7 验证** (上方 4 项机器化检测), 任一 fail → 立即修复 + 重 commit, 不算 review 完成。

历史反例: 2026-05-18 smart-uite re-review 阶段 OC-review 自刷 state.md 把 multi-line 注释简化为 single-line, 没自跑 B7, 漂移持续到 commit. 详见 F06-self.

### 同样适用其它 Agent

(v0.4 加) 所有刷 state.md 的 Agent (Codex 03c / OC-review / Codex 09-closeout) 都应在收尾必做加 B7 self-verify, 不只是 OC-review。
```

### 3. `oc-code-quality-rubric.md > B7` 验证段同步更新

(B7 出现在两处, 应一致, 避免 prompt 漂移)

### 4. (可选) 新建 `.ai/scripts/verify-state-md.sh` 一键脚本

```bash
#!/usr/bin/env bash
# B7 state.md 字段完整性 verify (v0.4 · F06-self)
# Usage: bash .ai/scripts/verify-state-md.sh
# Exit 0 if PASS, ≥ 1 if any check FAIL.

set -e
STATE_MD="${1:-.ai/state.md}"

# ... (上方 4 项机器化检测的 shell 化版本)
```

让各 Agent 收尾时统一调 `bash .ai/scripts/verify-state-md.sh`, 一键 PASS / FAIL。

## SemVer 影响

**MINOR** (新增 B7 验证子项 + 收尾自审钩子 · 不破坏 v0.3 旧 state.md / 旧 04 prompt 兼容 · v0.4 加的 grep 验证 PASS 的 state.md 在 v0.3 也合法)。

## 关联与对照

- 与 **F02** (state.md 字段漂移) 同根: F02 是 condensed 字段, F06-self 是 HTML 注释段闭合
- 与 **F08** (B7 加 state.md 完整性检查) 同根: F08 引入 B7, F06-self 扩展 B7 验证方法 + 加自审钩子
- 与 **F05-self** (子任务包必做段 override 03b 契约) 同形态: 都是"契约盲区导致 Agent 个体行为不可预测"; 本次 dogfood 同一 epic 触发两条
