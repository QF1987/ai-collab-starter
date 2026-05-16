# Session State (lite v0.1.0)

> Resume 协议。每个 Agent 完成后必须刷新本文件。
> 下一次开 session 第一件事:读这里就知道接哪一步。
>
> 与 `progress.md` 区别:progress 是流水账(追加),state 是当前快照(覆盖)。
>
> **lite vs main**: lite 无 Claude,4 终端拓扑 (Codex + OC-helper + OC-impl + OC-review + Human)。
> Escalation 接收方是 **Human**,不是 Claude main session。

## Active task

- 当前 task: `NONE`
- 当前阶段: `NONE` <!-- 02-plan / 03a-decompose / 03b-impl / 03c-verify / 04-review / merge / ... -->
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
     "(数量请 ls 实查)"。 -->


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

---

## 维护规则

1. 每次 Agent 完成时**覆盖**本文件(不是 append);旧快照已在 `progress.md` 流水账里。
2. `Next step` 的可粘贴 prompt 必须由 Agent 在自己的 `## 下一步提示词` 段产出后**抄进**这里。
3. session 中断后回来——**Pattern A**:你(Human)用眼读本文件 → 复制 `Next step.可粘贴 prompt` → 粘给对应终端。Agent **不读** state.md(它收到的 prompt 已自带完整上下文)。
4. 任务整体完成(merge + 文档收口都做完):清空 `Active task / Last completed step / Next step`,仅保留 `Notes` 给下个任务参考。
5. 多个并行任务:本文件**只**追当前活跃任务;其它任务用各自的 task 文件 `Handoff state` 段记录。

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
