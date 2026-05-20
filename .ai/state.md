# Session State (lite v0.6.0-lite-rc1)

> Resume 协议。每个 Agent 完成后必须刷新本文件。
> 下一次开 session 第一件事:读这里就知道接哪一步。
>
> 与 `progress.md` 区别:progress 是流水账(追加),state 是当前快照(覆盖)。
>
> **lite vs main**: lite 无 Claude,4 终端拓扑 (Codex + OC-helper + OC-impl + OC-review + Human)。
> Escalation 接收方是 **Human**,不是 Claude main session。
>
> **字段完整性硬约束 (v0.2.0 · F02 · F08-B7)**: 后续 Agent 刷本文件时, **必须保留本 template 所有字段名 + 维护规则段 + Pattern A/B 安全栏段 + 顶部说明段**。
> 字段值可改 (动态), 字段名 / 段结构不能漂移。违反 → OC-review 04 三步法第三步 B7 catch + 升 Human。

## Active task

- 当前 task: `NONE`
- 当前阶段: `NONE` <!-- 主线阶段 + 过渡态 (v0.2.0 · F13 + v0.3.0 加 01-intake):
     01-intake            · Codex 跑 ≤ 5 轮 Q&A 把一句话 → brief (v0.3 新增 · 可选起点)
     01-intake-done       · Q&A 完成, brief 文件已落 (v0.3 新增)
     02-plan              · Codex 出 brief 决策
     02-plan-refine       · brief 已出但需微 L2 / 用户反馈才能 finalize (v0.2 新增 · 诊断型必标 诊断轮 R<X>/3, v0.6 · F04-v0.6)
     03a-decompose        · Codex 拆 OC-impl 子任务包
     03a-prep             · 03a 前的微 L2 / 补查 (v0.2 新增)
     03b-impl             · OC-impl 写代码 (T3)
     03b-retry            · 03b 因 03c 退回重试 (轮次 X/3, v0.2 新增)
     03c-verify           · Codex 跑 rubric 验收
     04-review            · OC-review 三步法 (T4)
     04-fix-loop          · review 出 finding, OC-impl 修, OC-review 重审 (v0.2 新增)
     merge                · Human 合入
     <stage>-human-gate   · 任意阶段 Human 介入决策 (escalation / override, v0.2 新增)
                            子模式 codex-direct-solve: 诊断 stall 后 Codex 脱编排直接修 (v0.6 · F06-v0.6)
     -->
- 起始时间: `NONE` <!-- task 第一次启动时间(intake 完成那一刻);**跨 step 不变**,详见 AGENTS.md > Session State Discipline 字段表 -->
- 当前 epic 终端布局:
  - T1 Codex: `NONE`
  - T2 OC-helper: `NONE` (按需启动)
  - T3 OC-impl: `NONE`
  - T4 OC-review: `NONE`


## Last completed step

- Agent: `NONE` <!-- Codex | OC-helper | OC-impl | OC-review | Human -->
- Step: `NONE`
- 完成时间: `NONE`
- Commit: `NONE`
- 产出: `NONE`

<!-- 产出字段填写约定:
     不要手写具体 finding 文件清单,改写产出根目录(如 `.ai/logs/lite-v0.1-finding-*.md`)+
     "(数量请 ls 实查)"。
     (v0.2.0 · F14) 03a 阶段产出必含:
       - .ai/scratch/oc-impl-package-<task-id>-<n>.md (子任务包正文落档)
       - .ai/tasks/<task-id>.md Implementation slices 段更新 (若 paths 收紧) -->


## Next step

<!-- 校验规则(lite v0.1.0 · 3 类触发源):
  - 若 Last completed.Step 含 "03b-opencode-impl",则 Next step.Agent 必须是 Codex,
    Step = 03c-codex-verify (走 .ai/oc-code-quality-rubric.md 打分)
  - 若 Last completed.Step 含 "03c-codex-verify" 且通过,则 Next step.Agent = OC-review
    Prompt 模板 = 04-opencode-review.md
  - 若 03b ↔ 03c 已 3 轮仍 fail (progress.md 含 `03b-retry-count: 3`)
    → Next step.Agent = Human (lite 触发来源 H · 重试上限)
  - 若 OC-review 04 检出严重 finding (scope deviation / 架构敏感 / 安全)
    → Next step.Agent = Human (lite 触发来源 C · OC escalation)
  - 若 Codex 02-plan 自觉本 task 超能力 (frontmatter 含 `human-escalation-suggested: true`)
    → Next step.Agent = Human (lite 触发来源 A · 预声明)
  - 违反上述规则的 state.md 视为损坏,需 Human 复检
-->

- Agent: `NONE` <!-- Codex | OC-helper | OC-impl | OC-review | Human -->
- Prompt 模板: `NONE`
- 触发来源(lite): `NONE` <!-- A · pre-declared(brief 预声明) / C · OC escalation / H · 重试上限 / normal · 标准路径 -->
- 触发条件(lite): `NONE` <!-- A 填 frontmatter 字段值;C 填命中的 rubric 维度或安全 keyword;H 填 "03b-retry-count: 3" -->
- 输入: `NONE`
- 可粘贴 prompt(由上一步 Agent 自动生成):

```text
NONE
```

## Blockers

> 已知阻塞,不写「无」就是「无」。

无

## Notes

> 任何对未来 session 有用的当下细节。会被下次读到。

- 本项目是 lite 分支:2 Agent + 1 Human 协同 (Codex 脑力 + OC 体力 + Human bus)。详见 `AGENTS.md` 与 `.ai/getting-started.md`。
- 启动新任务:Human 直接在 T1 Codex 喂 `.ai/prompts/02-codex-plan.md` 契约的 prompt。
- OC-helper / OC-impl / OC-review 默认懒启动,等 Codex 第一次需要再开终端。
- 2026-05-16 20:48 CST: §B 共享文件协议 smoke 已跑通。Codex 写入 `.ai/scratch/oc-helper/req-smoke-1.md`, OC-helper 写回 `.ai/scratch/oc-helper/out-smoke-1.md`; grep `.ai/prompts/` 中 `pre-decisions` 共 13 条, `status: success`, `truncated: false`。
- 2026-05-16: §C 完整 epic smoke (4 终端 throwaway hello endpoint) 跑通, 5 关键检查 + 4 流程检查全过。Phase 5 Human gate 通过, 进 Phase 6 release v0.1.0-lite-rc1 (rc 因 throwaway 不算真实 epic dogfood)。

---

## 维护规则

1. 每次 Agent 完成时**覆盖**本文件(不是 append);旧快照已在 `progress.md` 流水账里。
2. `Next step` 的可粘贴 prompt 必须由 Agent 在自己的 `## 下一步提示词` 段产出后**抄进**这里。
3. session 中断后回来——**Pattern A**:你(Human)用眼读本文件 → 复制 `Next step.可粘贴 prompt` → 粘给对应终端。Agent **不读** state.md(它收到的 prompt 已自带完整上下文)。
4. 任务整体完成(merge + 文档收口都做完):**走 `workflow.md §9 Epic closeout` 完整 checklist** (v0.4 加 · F01-self), 不只是清空 `Active task / Last completed step / Next step` 三段, 还涉及 `.ai/scratch/` 清理 + `progress.md` append DONE 段 + `review.md` status 翻转 + `state.md` HTML 注释段闭合 self-verify (F06-self) 等。推荐喂 `.ai/prompts/09-codex-closeout.md` 让 Codex 协助。
5. 多个并行任务:本文件**只**追当前活跃任务;其它任务用各自的 task 文件 `Handoff state` 段记录。
6. (v0.5 · F06-v0.5) `Next step.Prompt 模板` 字段值必须是**实际存在的** `.ai/prompts/*.md` 文件路径, 或 `NONE` / `n/a` (无下一步 / 不适用)。填错路径 (e.g. `.ai/prompts/03c-codex-verify.md` 不存在 / `.ai/prompts/03-oc-impl.md` 笔误) 会被 OC-review 04 三步法第三步 B7 catch 升 Human。
7. (v0.5-rc1 patch · Pattern A 完整性) **每个 cross-terminal 切换点**, 当前 Agent 完成 step 时**必须填 `Next step.可粘贴 prompt` body** 为下一个 Agent 的具体启动 prompt (Human bus Pattern A 切换 terminal 时直接复制粘贴, 不需回头找契约)。具体切换点 (按 lite 4 终端拓扑):
   - 02 → OC-helper L2 (T1→T2): Codex 02 填 OC-helper req-* path + 启动 prompt
   - 03a → 03b (T1→T3): Codex 03a 填子任务包正文 (F14 双输出协同)
   - 03c → 04-review (T1→T4): Codex 03c 填 04 review 三步法启动 prompt
   - 04-review → 04-fix-loop (T4→T3): OC-review 填 OC-impl 04-fix-loop 修 RV prompt
   - **04-fix-loop → 04-re-review (T3→T4)**: OC-impl 填 OC-review re-review 启动 prompt (v0.5-rc1 patch 加 · 历史反例 h5coat-qt5core-missing epic)
   - 04-re-review → Human merge (T4→Human): OC-review 填 Human merge 决策指引
   - Human merge → 09-closeout (Human→T1): Human merge prompt 含 09-closeout 启动指引
   (v0.6 · F01-v0.6 扩展) cross-terminal 切换点 prompt body force, 不只 happy path, 还含 fallback / iteration 路径:
   - 02 → 02-plan-refine 第 N 轮 (Codex 02 brief fallback 决策树触发) — Codex 02 必预填 (见 `02-codex-plan.md > 多分支 fallback 决策树`)
   - Human gate → 02 退回 (Human gate 不接受 Decision) — Codex 02 必预填 reroll prompt
   - 03b → 03b-retry (03c 退回, 轮次 X/3) — Codex 03c 退回模板必预填完整 paste-able OC-impl 重试 prompt
   - 04-fix-loop → 03b/02 退回 (RV fix 不通过) — OC-review 必预填
   - OC-helper L2 done → Codex 02 finalize (T2→T1) — Codex 02 写 OC-helper req 时同时预填 finalize prompt body
   不填 / 填错 prompt body → 违反 Pattern A 设计意图, 04 三步法第三步 B7 catch + 升 Human。

## Human vs Agent · 谁该读 state.md

| 角色 | 是否读 state.md | 何时读 |
| --- | --- | --- |
| **Human** | **是** | 每次开新 session / 切终端前 |
| **Codex / OC-***(默认) | **否** | 它收到的 prompt 自带上下文,不需要 state |
| **Codex / OC-***(Pattern B) | 是 | 仅当 Human 显式说「读 state.md 按 Next step 继续」 |

### Pattern B 的安全栏

如果 Agent 被指令读 state.md:

1. **必须先核对** `Next step.Agent` 与自己角色一致。不一致直接拒绝执行,告诉 Human「我不是这一步该上场的 Agent,你应该粘给 X」。
2. **必须扫 Blockers**。非空时不要直接执行,先让 Human 确认阻塞已解除。
3. **不接管多步**——只执行 Next step 这一步,下一步仍由 Human 接力。

lite 中 OC 是国产模型,Pattern B 安全栏不一定靠谱,**强烈建议优先用 Pattern A**。
