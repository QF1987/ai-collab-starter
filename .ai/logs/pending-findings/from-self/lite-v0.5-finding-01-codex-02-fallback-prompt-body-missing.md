---
finding-id: lite-v0.5-finding-01-codex-02-fallback-prompt-body-missing
severity: P2
category: prompt + critical-pattern-A-gap
source-project: lite-self (v0.5.0-lite-rc1 sync 后第 1 个 epic · smart-uite daemon-dcbusinessmanager-error2 02 plan finalize 后 Human 测 workaround 触发)
discovered: 2026-05-19
target:
  - .ai/prompts/02-codex-plan.md (输出格式末 "Next step.可粘贴 prompt" 段加多分支 fallback 子段)
  - .ai/state.md (维护规则 7 扩展: cross-terminal 切换点 fallback / iteration 路径 prompt body 也必须 force 预填)
  - .ai/prompts/03-codex-orchestrate.md (03c 退回 / 03b-retry / 04-fix-loop 退回路径 同协同)
status: pending
related: [F03-v0.5, F01-v0.5, v0.5-rc1-patch]
---

# Finding F01-v0.6: Codex 02 brief Next step.可粘贴 prompt 只预填 happy path, 没预填 fallback / iteration 分支 prompt body — 违反 Pattern A 设计意图

## 现象

smart-uite v0.5.0-lite-rc1 sync 后第 1 个 P0 epic `bug-20260519-daemon-dcbusinessmanager-error2`, 02 plan finalize 完成. Codex 02 brief 主动加 ## Quick workaround 段 (F03-v0.5 守约) + Next step.可粘贴 prompt body 含 5 步 Human gate 指引, 但第 5 步只是**文本叙述指令**:

```
5. 若仍弹 boost DLL, 回复完整 DLL 名称/截图, 回 02 补 OC-helper DLL 依赖扫描。
```

**没预填**具体 Codex 02-plan-refine 第 2 轮的 prompt body。Human 实际测 workaround 后撞 boost_atomic-vc143-mt-x32-1_87.dll 缺失 (A3 假设错), 需要触发第 5 步 fallback, **但 Human 不会写 "回 02 补 OC-helper req" 的完整 prompt** (含 grep pattern / context_lines / additional_exclude_dirs / cwd_override / output_format 等 OC-helper 契约要求字段).

Human 反馈: "这样的给 codex 的提示词 human 很难写出".

Claude 写了 30 行 fallback prompt 临时解, 但**这违反 Pattern A 设计意图** (Human bus 只复制粘贴, 不自己写). 生产环境没 Claude 实时审, Human 撞 fallback 就卡。

## 影响

- **Pattern A 设计意图在 fallback / iteration 路径失效**: Pattern A 是 Human bus 接力时**只看 state.md 复制粘贴, 不自己写 prompt**. 但当前 Codex 02 brief 只预填 happy path prompt, 撞 fallback 时 Human 必须自己拼 prompt body (含 OC-helper req 字段 / GitNexus query / state.md 刷新格式 / B7 self-verify 钩子等), 难度高
- **v0.5-rc1 Pattern A 完整性 patch (维护规则 7) 覆盖不全**: 只列了 7 个 cross-terminal **happy path 切换点**, **没覆盖**:
  - 02-plan-refine → 02-plan-refine 第 N 轮 (A1/A2/A3 假设错 / workaround fail 各种 fallback)
  - 02 → 02 退回 (Human gate 不接受, 退回 02 重审)
  - 03b-impl → 03b-retry (03c 验收退回, 轮次 X/3)
  - 04-fix-loop → 03b/02 退回 (RV fix 不通过)
  - **OC-helper L2 done → Codex 02 finalize (T2→T1)** (新 case · 2026-05-19 实战触发 · Codex 02 写 OC-helper req 时同时预填"OC-helper done 后 → Codex finalize"prompt body 到 state.md, 让 Human 看 state.md 知道复制粘贴, 不自己拼)
- **生产环境严重**: derived 项目用户没 Claude 实时审, 撞 fallback 时 Human 卡 / 自己写 prompt 容易写错 / 或放弃 lite 流程
- **跨 epic 历史**: 之前 epic Claude 帮 user 写过类似 fallback prompt 多次 (daemon-business-manager-not-started VM stuck 重启后补跑 / h5coat-start-fails RV-05 commit 修复 prompt 等), 都是同根问题但当时没被 catch 为 framework gap

## 根因

`02-codex-plan.md > 输出格式` 当前 Next step.可粘贴 prompt body 只要求 happy path prompt (单一 prompt body), 没要求 Codex 02 brief 预填**多分支 fallback prompt**.

实际 P0 任务的 Next step.可粘贴 prompt 应该是个**决策树**, 含:
- Branch 1 · Happy path (workaround 解决 + A1/A2/A3 全 confirmed): "→ 03a 启动 prompt"
- Branch 2 · Fallback A: workaround 后弹另一 DLL (A3 假设错): "→ 02-plan-refine 第 2 轮 prompt (补 OC-helper DLL 依赖扫描)"
- Branch 3 · Fallback B: workaround 没解决 (A1/A2 假设错): "→ 02-plan-refine 修订 Cross-check confirmed prompt"
- Branch 4 · Fallback C: Human 不接受 Decision: "→ 02 退回 reroll prompt"
- Branch 5 · 完全意外的 error: "→ 升 Human + Claude/外部审计"

`state.md > 维护规则 7` (v0.5-rc1 patch 加的) 只列了 happy path cross-terminal 切换点, 没覆盖 fallback / iteration 切换点的 prompt body force.

## 证据

- smart-uite 2026-05-19 daemon-dcbusinessmanager-error2 02 plan finalize 后 Next step.可粘贴 prompt body 第 5 步: "若仍弹 boost DLL, 回复完整 DLL 名称/截图, 回 02 补 OC-helper DLL 依赖扫描" — **文本叙述, 不是 paste-able prompt**
- Human 撞 boost_atomic 缺失后问 Claude "接下来怎么办", Claude 写 30 行 fallback prompt — Human 反馈"这样的给 codex 的提示词 human 很难写出"
- 跨 epic 类似反例多次: daemon-business-manager-not-started VM stuck 后 Claude 写"补跑 ps1" prompt / h5coat-start-fails RV-05 OC-impl commit fix prompt (虽然 OC-review 04 prompt body 含 RV-05 expected fix, 但 Human 切到 T3 时需重新组织成 OC-impl 启动 prompt — 实际是边界 case, 不算严重)

## 提议修复

### 1. **`02-codex-plan.md > 输出格式`** Next step.可粘贴 prompt 段改为多分支 fallback 决策树

```markdown
## Next step.可粘贴 prompt (含 fallback 决策树 · v0.6 · F01-v0.6)

> P0/P1 必填 ≥ 2 branch (happy + ≥ 1 fallback); P2/P3 可只填 happy path。
> 每 branch 必须是**完整 paste-able prompt body** (不允许文本叙述指令), Human 看 brief 知道每个分支具体粘哪段。

### Branch 1 · Happy path (workaround 解决 + Assumptions 全 confirmed)

```text
你是 Codex。按 .ai/prompts/03-codex-orchestrate.md 契约执行 03a 拆 OC-impl 子任务包.
[完整启动 prompt body, 含必读输入 + 任务一句话 + 完成后动作]
```

### Branch 2 · Fallback: workaround 后弹另一错误 (Assumption A3 失败)

```text
你是 Codex。Human 反馈 workaround 解了 X 但弹 Y. A3 假设错.
按 .ai/prompts/02-codex-plan.md 契约执行 02-plan-refine 第 2 轮:
1. 写 OC-helper req .ai/scratch/oc-helper/req-<epic>-N.md, 扫 <具体 keyword>
2. 等 OC-helper out 后 finalize 修订 Decision/ADR
3. 给新 quick workaround
4. 刷 state.md (含 v0.5 维护规则 6/7)
```

### Branch 3 · Fallback: workaround 没解决 (Assumption A1/A2 失败)
... [类似具体 paste-able prompt]

### Branch 4 · Fallback: Human 不接受 Decision (退回 02)
... [类似]

### Branch 5 · 意外 error (升 Human + 外部审计)
... [简短 escalation 指引]
```

#### 必含字段

- **每个 branch 名称**: 触发条件 (一句话)
- **每个 branch prompt body**: 完整 paste-able (Codex 拿到能立刻跑), 不允许 "若 X, 做 Y" 文本叙述
- **决策决策点**: 给 Human 一眼判断当前是哪 branch (e.g. "若弹 DLL 错误 → Branch 2; 若错误消息跟原 bug 一样 → Branch 3")

### 2. **`state.md > 维护规则 7`** 扩展含 fallback / iteration cross-terminal 切换点

```markdown
7. (v0.6 · F01-v0.6 扩展) cross-terminal 切换点 prompt body force, 不只 happy path, 还含:
   - 02 → 02-plan-refine 第 N 轮 (Codex 02 brief 第 5 步 fallback 触发) — Codex 02 必预填
   - Human gate → 02 退回 — Codex 02 必预填 (Human gate 不接受时)
   - 03b → 03b-retry (轮次 X/3) — Codex 03c 退回模板必预填
   - 04-fix-loop → 03b/02 退回 — OC-review 必预填
   不预填 → 04 B7 catch + 升 Human (Pattern A 失效 fallback 路径)
```

### 3. **`03-codex-orchestrate.md > 03c 退回模板`** 同步扩展 (fallback path prompt body force)

```markdown
退回模板 (Codex 03c → OC-impl):
[现有内容]

(v0.6 · F01-v0.6) 退回模板必须含 paste-able OC-impl 重试 prompt, 而非叙述指令.
```

## SemVer 影响

**MINOR** (新增 02 输出格式 多分支 prompt body + state.md 维护规则 7 扩展 + 03c 退回模板扩展 · 不破坏 v0.5 旧 brief · 旧 brief 没多分支 prompt body 仍合法但不达 v0.6 best practice; Pattern A fallback 路径失效问题对生产环境严重 → 建议优先 v0.6 实施).

## 关联

- 与 **v0.5-rc1 Pattern A 完整性 patch (维护规则 7)** 同根: patch 覆盖 7 个 happy path 切换点, F01-v0.6 扩展 fallback / iteration 路径
- 与 **F03-v0.5 Quick workaround 段** (v0.5) 协同: F03 让 Codex 02 给 quick hotfix 路径, F01-v0.6 让 Codex 02 给 quick hotfix **失败后** 的 fallback prompt path
- 与 **F01-v0.5 Assumptions to verify** (v0.5) 协同: Assumptions 列假设, F01-v0.6 让每个假设失败时有对应 fallback prompt
- 跨 epic 累积观察: lite Pattern A 在 happy path 工作完美 (跑通 5 个 epic), 但 fallback 路径每次都靠 Claude 临时写 — 第 1 次出现在 daemon-business-manager-not-started VM stuck, 持续到本 epic, 现在终于被 Human 显式 catch
