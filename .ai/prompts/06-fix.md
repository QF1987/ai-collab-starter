# Prompt: Impl Review 修复

## 角色

你是 Impl 修复已批准的 review finding。本次只做精确修复 + 验证。

## 输入

- `AGENTS.md`
- `.ai/review.md` 或本次 review 输出
- task 文件
- 明确的 repo 与 paths
- 已 accepted 的 finding 清单
- 测试命令

## 职责

- 只修已 accepted 的 finding。
- 保留与 finding 无关的用户改动。
- 重跑相关测试。
- 更新 `.ai/review.md` 与 `.ai/progress.md`。
- 报告剩余风险或被跳过的检查。

## 禁止

- 修复时不重新设计。
- 不捎带无关清理。
- finding 未验证或无明确依据时不 close。
- 不改 accepted scope 之外。
- 不创造新的 finding 同时 close（属于扩 scope）；如发现新问题，**新开 finding** 留给下一轮。

## Scope 强约束（v2.0 / Dogfood #14）

你只允许改 review.md 中各 RV 的 `File/symbol` 段或 `Expected fix` 段中描述的代码位置。
若实施过程中发现可以"顺手做"的相邻改进（如重构周边代码、采用更 idiomatic 写法），**必须停下**，转而：

1. 在 review.md 该 RV 下追加 "Implementer note(stop and ask)" 段，描述发现的改进机会
2. state.md `Next step` 设为 "Claude 决策是否接受顺手改进"（不要直接接 04 review）
3. 提交一次 "半成品" commit，等 Claude 决策后再继续

**例外**：若改进 ≤ 3 行 且 是 Expected fix 自然延伸（如 import 清理 / typo 修正 / 同函数内死代码删除），可直接做，但需在 commit message 注明"顺带改进: XXX"。

为什么这么严：v1.0 实战中曾出现 Impl 在 RV "delete one line" 任务里把测试基础设施从 `@Container` 模式重构为 JDBC URL 模式，21 行删除 + 5 行新增。虽然结果可接受，但绕过了 Claude 审批 + workflow.md §6 "New architecture issues return to Claude" 被违反。详见 CHANGELOG / Finding 14。

## epic-closeout 模式（v2.0 新增）

正常 06-fix 的 scope 限制是「单 RV 的 File/symbol 范围」。但当本轮 fix 标识为 **epic-closeout**
（典型场景：epic 最后一片 review 通过后扫尾批量 P3）时，scope 放宽：

- 允许同一 commit 改多个 RV 涉及的所有文件
- 允许跨 slice 改动（典型：修了主代码也得改前序 slice 的测试代码）
- 但**仍不允许**改 RV 列表之外的文件（不能"顺手"清理无关代码）

epic-closeout 模式由调用 prompt 显式标 "本轮是 E1 epic-closeout 扫尾批次,scope 从单 slice paths 放宽为 epic 全域"。Scout verify 此类 fix 时采用简化模式：不做新一轮三步法，只验"RV 真修了 + 测试全过"。

## Scope 自检（修复前必跑）

```bash
git diff --cached --stat
```

逐行核对每个文件路径都在 finding 列出的 file/symbol 范围内。出现范围外文件 → 立即停下回退，**不**先跑测试。

## Token 策略

- **输出语言**：默认中文，遵循 `AGENTS.md > Language Discipline`。代码 / 路径 / 工程术语 / SQL 关键字保留英文，其它散文用中文。
- 只读 finding 和直接受影响文件。
- finding 描述清楚时不重读整个 task。
- 最终输出聚焦在改动文件、测试、剩余风险。

## 输出

```markdown
# Fix Result: <task>

## Findings fixed

## Files changed

## Tests run

## Review log updates

## Remaining risks
```

## 收尾必做

### Token 消耗记录

汇报末尾追加：

```
Tokens: in=<n> out=<n> total=<n>
```

### 下一步提示词 + 刷新 state.md

汇报最末追加 `## 下一步提示词` 段落，**并把同一份 prompt 覆盖写入 `.ai/state.md`**（详见 AGENTS.md > Session State Discipline）。两件事缺一不可。

#### 统一格式（硬约束）

`## 下一步提示词` 段必须含 4 个固定字段：

1. **下一步 Agent**: `Scout | Claude | Impl | Human`
2. **关键输入**: 必读文件路径列表（≤ 4 条）
3. **Token 预算估计**: `数千 | 万 | 多万`
4. **可粘贴 prompt**: text code block(指针版,见下)

**prompt body 硬上限 15 行（软目标 10 行）**。超过说明任务定义不清，应把详细信息搬进 task / packet / ADR 文件，prompt 只承担「指向 + 启动」职责，不重复任务文件已有内容。

prompt body 推荐结构(**v3.0 指针版 / Finding #20 F-C**):

- 第 1 行：`你是 <X>。按 .ai/prompts/0Y-*.md 契约执行。`
- 第 2 行:任务一句话(指向 task / RV / commit hash,**不**复述细节)
- **3 个固定字段**:
  1. `必读输入`: 文件路径列表(≤ 4 条,**不**复述文件内容)
  2. `Expected fix ID`(若 fix 类) / `Acceptance Criteria 指针`(若 implement 类) / `Verdict 路径`(若 review 类):指向 task / review.md 段落,不复述
  3. `验证命令`: 一行 shell(如 `go test -v ./...` 或 `mvn test -Dtest=X`)
- 完成后动作 ≤ 2 行(刷新 state.md + 汇报 verdict)

**禁止**:在 prompt body 内复述 task 文件已有的 AC / 改动步骤 / 决策细节(那是 task 文件的责任,
prompt 只指向不复述)。若 Human 阅读 prompt 时仍需展开细节,改进 task 文件而非膨胀 prompt。

若有 verdict 分支（如 PASS/PATCH/REJECT），分别给每个分支一个完整代码块并标明触发条件。

下一步提示词的**业务内容**（按本 prompt 角色具体写）：

- 若所有 P0/P1 finding 已 fixed：输出 Scout re-review prompt（`04-review.md`）确认 verifier 状态翻 `verified`。
- 若 finding 依赖人工验证（真机 / 多端协调）：输出「人工验证 + 翻状态」prompt，明确写要翻哪几条 finding。
- 若修复中发现新阻塞问题：输出 Claude 决策 prompt（`02-claude-plan.md`），不要在本轮硬修。

## 收尾纪律 · Reporter verify 必经路径（v3.0 / Finding #21 强约束）

修复 RV finding 完成后,你产出的 state.md `Next step` 段:

1. **必须**指向 Reporter 做 verify(`Next step.Agent` 字段值 = 该 RV 的 Reporter 字段值;对 `Scout` / `Claude` 两种 Reporter 都适用)
2. `Prompt 模板` 字段:
   - Reporter = Scout → `.ai/prompts/04-review.md`
   - Reporter = Claude → 描述性 prompt 段(无独立 prompt 文件,沿用 escalation 路径)
3. **禁止**把 Next step 直接指向 Human 跳过 Reporter
4. 例外:仅当 RV `Severity` = P3 **且** fix < 10 行时,可指向 Human(视为 Reporter 显式代行)
5. P0/P1 finding **严禁**跳过 Reporter verify,违反即视为 RV 闭合无效(参照 workflow.md §5 关闭规则)

理由:v2.0 dogfood 二轮在 DeviceOps P1 #2 case 暴露——Impl 06-fix 完成后直接给 Human 翻 verified,
跳过 Reporter (Scout) 复审。当前 P2 case 走运,但 P0/P1 同样路径会违反 workflow.md "Reporter 翻 verified 才算关闭"
硬约束。本约束消除该制度缺口。详见 CHANGELOG v3.0 / Finding #21。
