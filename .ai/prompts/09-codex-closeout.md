# Prompt: Codex 09-closeout · Epic 收口 (lite v0.5.0-lite-rc1)

## 角色

你是 Codex, 在 lite 分支承担 **epic 收口 (closeout)** 职责。

**为什么有这个 prompt**: lite v0.3 之前 epic 收口纪律分散在 3 处 (state.md 维护规则 4 / workflow.md §8.4 / .gitignore), Human 不知道清哪些 / 留哪些, 易清漏或清过头。v0.4 加 Codex 协助 closeout — Human 一句话触发, Codex 跑 cleanup checklist + 验证。

## 输入

- Human 喂的一句话: `epic <id> 完了, merge commit <hash>, outcome: <一句话>`
- `workflow.md §9 Epic closeout (收口)` 完整 checklist
- 当前 `.ai/state.md` (Pattern A 例外 · closeout 必读 state.md 验证前置条件)
- 当前 `.ai/review.md` (验证有无 open finding)

## 4 步流

### Step 1: 验证前置条件 (硬约束 · 任一不满足 → 停止 + 输出 BLOCKED)

- ✅ `.ai/review.md` 无 open finding (`grep -c 'Status:\s*open' .ai/review.md` = 0; 例外: P3 long-term defer 可有, 但必须显式标 "→ Human" defer)
- ✅ merge commit `<hash>` 存在 (`git -C <repo> rev-parse --verify <hash>`; umbrella + 子仓 都要 verify, 若 multi-git topology)
- ✅ `.ai/state.md` `Active task.当前 task` 字段值 = `.ai/tasks/<epic-id>.md` 或与 `<epic-id>` 字符串一致 (防误收口别的 task)
- ✅ working tree clean 或仅含 closeout 文件 (state.md + progress.md)

任一不满足 → chat 输出:
```
BLOCKED: <具体哪条不满足> · <修复建议 1 句>
不执行 Step 2-4, 等 Human 处理后重跑 09-closeout.
```

### Step 2: 清 (ephemeral, per-epic)

按 workflow.md §9 checklist "🗑️ 必清" 段操作:

#### 2a. scratch 备份到 archived (审计追溯 · 选项 B 默认)

```bash
EPIC_ID=<epic-id>
mkdir -p .ai/logs/archived/$EPIC_ID/scratch
cp -r .ai/scratch/oc-helper/req-${EPIC_ID}-*.md \
      .ai/scratch/oc-helper/out-${EPIC_ID}-*.md \
      .ai/scratch/oc-helper/gitnexus-${EPIC_ID}-*.md \
      .ai/scratch/oc-impl-package-${EPIC_ID}-*.md \
      .ai/logs/archived/$EPIC_ID/scratch/ 2>/dev/null || true
```

#### 2b. scratch 清空

```bash
rm -f .ai/scratch/oc-helper/req-${EPIC_ID}-*.md \
      .ai/scratch/oc-helper/out-${EPIC_ID}-*.md \
      .ai/scratch/oc-helper/gitnexus-${EPIC_ID}-*.md \
      .ai/scratch/oc-impl-package-${EPIC_ID}-*.md
```

#### 2c. state.md 三段重置 (surgical edit)

**硬约束 · v0.2 F02 + v0.4 F06-self**: 保留完整 template 结构 + HTML 注释段闭合 + 维护规则段 + Pattern A/B 段。
只把以下字段值改为 `NONE`:

- `Active task.当前 task` / `当前阶段` / `起始时间` → NONE
- `Active task.当前 epic 终端布局.T1/T2/T3/T4` → 空闲
- `Last completed step.Agent / Step / 完成时间 / Commit / 产出` → NONE
- `Next step.Agent / Prompt 模板 / 触发来源 / 触发条件 / 输入 / Token 预算估计` → NONE
- `Next step.可粘贴 prompt` → `NONE` (单行)
- `Blockers` → "无"

**禁止**:
- 简化 multi-line HTML 注释为 single-line (会破坏注释段闭合 · F06-self 反例)
- 删 template 字段名或段标题
- 删 维护规则段 / Pattern A/B 段 / 字段完整性硬约束段

#### 2d. state.md Notes 段清理纪律 (F01-self 提议)

**清掉**:
- epic 内临时上下文 (e.g. "02 L2 关键结论" / "03b 第 N 轮" / "scratch 路径 X" 这类 working state)
- 已失效路径引用 (e.g. .ai/scratch/* 路径, 因 2b 已 rm)

**保留**:
- epic merge commit hash + 一句话 outcome (e.g. "2026-MM-DD <epic-id> merge commit XXX outcome: YYY")
- 长期 follow-up (e.g. open RV finding defer / 后续 task 提示)
- 项目个例 Known Sharp Edges 候选 (若有 dogfood 学到的环境/工具特定经验, 列在这里, 帮 Human 评估是否同步到 AGENTS.md)

### Step 3: 留 (持久 / 审计追溯)

按 workflow.md §9 checklist "📌 必留" 段操作:

#### 3a. progress.md append epic DONE 段 (硬约束)

```markdown
## <epic-id> · DONE

- 完成日期: YYYY-MM-DD
- merge commit(s): <hash 列表, 多 git topology 各列 1 行>
- 流转: <一句话从 01-intake → ... → merge 全流程, 含 retry-count 和关键节点>
- 残留 follow-up (若有): <RV-NN 说明 + 触发条件>
- lite framework finding 产出 (若有 dogfood 触发): N 条, 已落 from-self/ inbox 等下个 lite 升级仪式
- 强约束生效清单: <列本 epic 触发了 lite 哪些强约束 (F02/F05/F07/F10 等), 帮 lite owner 评估 v0.X+1 是否能翻 stable>
```

#### 3b. review.md status 翻转 (硬约束)

```bash
# 遍历本 epic 所有 RV finding (按 task-id 或 source-project), 翻 status
# Status: verified (Human accepted + verifier 签字) or closed (deferred not addressed)
# 不删 RV 行, 仅翻 Status 字段值
```

例外: RV-NN 标 "→ Human" defer 的, 保留 status: open + 显式 reason, **不算违约**。

#### 3c. AGENTS.md > Known Sharp Edges 评估

读 step 2d 留下的 "项目个例 Known Sharp Edges 候选", 评估是否 append 到 `AGENTS.md > Known Sharp Edges`:
- 是 dogfood 学到的工具 / 环境 / 编码 / 平台特定经验 → append
- 是 lite framework finding (从 self / derived 触发) → **不** append (落 inbox 等 lite 升级, 不放项目 AGENTS.md)

### Step 4: 收口验证 (机器化 · 硬门槛)

```bash
# 1. state.md 三段已重置
[ "$(grep -c 'NONE' .ai/state.md)" -ge 14 ] && echo "state PASS" || echo "state FAIL"

# 2. state.md HTML 注释段闭合 (F06-self · v0.4 加)
OPEN=$(grep -c '<!--' .ai/state.md)
CLOSE=$(grep -c '\-\->' .ai/state.md)
[ "$OPEN" = "$CLOSE" ] && echo "comments balanced ($OPEN/$CLOSE)" || echo "FAIL comments: $OPEN open vs $CLOSE close"

# 3. scratch 清空
LEFT=$(find .ai/scratch -type f -name "*${EPIC_ID}*" 2>/dev/null | wc -l | tr -d ' ')
[ "$LEFT" = "0" ] && echo "scratch clean" || echo "FAIL: $LEFT files remaining"

# 4. progress.md 含 epic DONE 段
grep -q "^## ${EPIC_ID} · DONE" .ai/progress.md && echo "progress PASS" || echo "FAIL: no DONE section"

# 5. review.md 无 P0/P1 open
[ "$(grep -c 'Severity:.*P[01]\b.*\n.*Status:\s*open' .ai/review.md 2>/dev/null)" = "0" ] && echo "review PASS" || echo "FAIL: P0/P1 open"

# 6. Prompt 模板路径存在 (v0.5 · F06-v0.5)
PROMPT_TEMPLATE=$(grep '^- Prompt 模板:' .ai/state.md | head -1 | sed 's/^- Prompt 模板: *`*\([^`]*\)`*.*/\1/' | sed 's/ *$//')
if [ "$PROMPT_TEMPLATE" = "NONE" ] || [ "$PROMPT_TEMPLATE" = "n/a" ]; then
  echo "Prompt template OK (NONE / n/a · closeout 后无下一步是正常的)"
elif [ -f "$PROMPT_TEMPLATE" ]; then
  echo "Prompt template OK ($PROMPT_TEMPLATE exists)"
else
  echo "FAIL: Prompt template $PROMPT_TEMPLATE not found"
fi
```

6 项全 PASS → closeout 完成, chat 输出:

```
✅ closeout done · <epic-id>
state.md: reset OK
scratch: archived to .ai/logs/archived/<epic-id>/scratch/ + cleaned
progress.md: DONE section appended
review.md: <N> RV verified/closed, <M> defer to Human

下个 epic: 全新 Codex/OpenCode chat session (epic 间清零 · workflow §0)
```

任一 fail → 立即输出 "FAIL: <哪条>" + 停止, 等 Human 处理。

## 禁止

- 跳过 Step 1 前置条件验证 (review.md 有 open finding 时强制收口)
- 删 `.ai/tasks/<epic-id>.md` (epic 文档应保留, 长期 reference)
- 删 `.ai/decisions.md` (ADR 永久保留)
- 删 `.ai/progress.md` 历史段 (append-only)
- 删 `.ai/review.md` 行 (只翻 status, 不删行)
- 简化 state.md HTML 注释段 (F06-self 反例)
- 在没 merge commit 时收口

## Token 策略

- **输出语言**: 默认中文
- chat 输出极简 (Step 1 BLOCKED / Step 4 PASS 状态 + verify 数字)
- 不在 chat 复述清掉了哪些 scratch 文件 (走 archive 文件夹审计追溯, chat 只说"archived to X")

## 收尾必做

### state.md self-verify (F06-self · 刷完后必跑)

Step 4 第 2 项 (HTML 注释闭合 verify) 即此 self-verify。closeout 是最后一个刷 state.md 的 Agent, 必须 self-verify 通过才算完成。

### 不写"下一步提示词"

closeout 完成后没有"下一步" (epic 结束, 等 Human 启动下个 epic, 状态由 Human bus / 01-intake 主导)。state.md `Next step` 已重置为 NONE, 表示"无下一步"。

### Token 消耗记录

```
Tokens: in=<n> out=<n> total=<n>
```

## 关联文档

- `.ai/workflow.md > §9 Epic closeout (收口)` — 完整 checklist
- `.ai/state.md > 维护规则 4` — 任务整体完成清空指引 (lite v0.3 起跳 §9 完整 checklist)
- `.ai/getting-started.md > §四 Epic 收口` — Human 入口段
- `.ai/logs/pending-findings/from-self/lite-v0.3-finding-01-epic-closeout-checklist.md` — 本能力来源 dogfood finding
