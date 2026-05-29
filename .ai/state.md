# Session State

> Resume 协议。每个 Agent 完成后必须刷新本文件。
> 下一次开 session 第一件事：读这里就知道接哪一步。
>
> 与 `progress.md` 区别：progress 是流水账（追加），state 是当前快照（覆盖）。

## Active task

- 当前 task: `NONE`
- 当前阶段: `NONE`
- 起始时间: `NONE` <!-- task 第一次启动时间（intake 完成那一刻）；**跨 step 不变**，详见 AGENTS.md > Session State Discipline 字段表 -->


## Last completed step

- Agent: `NONE`
- Step: `NONE`
- 完成时间: `NONE`
- Commit: `NONE`
- 产出: `NONE`

<!-- 产出字段填写约定（v2.0）：
     不要手写具体 finding 文件清单（如 "finding-01..04"），改写产出根目录（如 `.ai/logs/starter-v2-finding-*.md`）+
     "(数量请 ls 实查)"。原因：分阶段产出时容易摘要滞后于实际文件状态（Finding 07）。 -->


## Next step

<!-- 校验规则（v4.0 多源触发机制 + v2.0 闸门）:
  - 若 Last completed.Step 含 "03-implement"，则 Next step.Agent 必须是 Scout
    且 Prompt 模板必须是 04-review.md（除非 task 文件显式标 `skip-review: true`）
  - 若 task frontmatter `claude-review-required: required` → Next step.Agent 必须为 Claude(触发来源 A)
  - 若 progress.md 含 `self-flag(Impl): needs Claude` → Next step.Agent 为 Claude(触发来源 B)
  - 若 Scout review 检出 scope-deviation / 架构敏感改动(参考 04-review.md Escalation 判定表 C1-C7)
    → Next step.Agent 为 Claude(触发来源 C, 写明命中的 C 编号)
  - 若 06-fix 完成且 RV severity = P0/P1 → Next step.Agent 必须为 Reporter(通常 Scout 或 Claude)
    (触发来源 D · Auto-P0/P1 / 详见 06-fix.md 收尾纪律 v3.0)
  - 若 04-review verdict = `NEEDS-EXECUTION`(E2E/真机/集成切片设计完整但未实测 / 证据是模板占位符,v5.3.0 · deviceops-finding-28)
    → Next step.Agent 必须为 Impl,prompt 写明「跑哪个脚本 / 哪台真机 / 回填哪个 summary」;**不**标 epic CLOSED
  - 违反上述规则的 state.md 视为损坏，需 Claude 复检后才能继续
  - 若本步在 worktree 中执行（pwd 含 `.claude/worktrees/`），Next step.可粘贴 prompt 必须以 `⚠️ 粘贴前请先 rsync 回主仓` 起头
-->

- Agent: `NONE`
- Prompt 模板: `NONE`
- 触发来源(v4.0): `NONE` <!-- A · pre-declared / B · Impl self-flag / C · Scout escalation / D · Auto-P0/P1 / normal · 标准路径 -->
- 触发条件(v4.0): `NONE` <!-- 若触发来源 = A,填 task frontmatter 字段值;C 填命中 C1-C7 编号;B/D 填一句话理由 -->
- 输入: `NONE`
- 可粘贴 prompt（由上一步 Agent 自动生成）：

```text
NONE
```

## Blockers

> 已知阻塞，不写「无」就是「无」。

无

## Notes

> 任何对未来 session 有用的当下细节。会被下次读到。

- 本项目使用多 Agent 协同框架，详见 `AGENTS.md` 与 `.ai/getting-started.md`。
- 启动新任务建议用 `/intake` skill（Claude Code）或读 `.ai/intake-templates.md`（Scout/Impl）。

---

## 维护规则

1. 每次 Agent 完成时**覆盖**本文件（不是 append）；旧快照已在 `progress.md` 流水账里。
2. `Next step` 的可粘贴 prompt 必须由 Agent 在自己的 `## 下一步提示词` 段产出后**抄进**这里。
3. session 中断后回来——**默认 Pattern A**：你（人）用眼读本文件 → 复制 `Next step.可粘贴 prompt` → 粘给对应 Agent。Agent **不读** state.md（它收到的 prompt 已自带完整上下文）。
4. 任务整体完成（merge + 文档收口都做完）：清空 `Active task / Last completed step / Next step`，仅保留 `Notes` 给下个任务参考。
5. 多个并行任务：本文件**只**追当前活跃任务；其它任务用各自的 task 文件 `Handoff state` 段记录。
6. **state ≠ progress 红线**（v5.2.0-rc2 · deviceops-finding-26）：本文件只承载「resume 所需的最小快照」。详细 R1-Rn 摸排发现、token 消耗统计、prompt drafting 备忘、epic 教训复盘等**全部放别处**（packet / progress.md / 独立 lessons 文件），state.md 留指针即可。
   - ❌ 反例：把 context packet 的 R1-R7 全文 copy 到 `Last completed step.产出`
   - ❌ 反例：`Token 消耗 in≈178000` 历史统计塞进 `Last completed step`
   - ✅ 正例：`产出: .ai/logs/<packet>.md（R1-R7 全覆盖）；关键校正 1 行指针`
   - 合理快照行数 ≤ 80 行；超 100 行说明已膨胀，按本规则瘦身
7. **`Next step.可粘贴 prompt` body 硬上限 15 行**（对齐 `02-claude-plan.md` 收尾段约束，v5.2.0-rc2 · deviceops-finding-26）。超过说明任务定义不清，应把详细信息搬进 task / packet / ADR，prompt 只承担「指向 + 启动」职责。
   - 自检：每次写完 Next step prompt 后 `wc -l` 数一下 fence 内行数

## 人 vs Agent · 谁该读 state.md

| 角色 | 是否读 state.md | 何时读 |
| --- | --- | --- |
| **人** | **是** | 每次开新 session 第一件事 |
| **Agent**（默认） | **否** | 它收到的 prompt 自带上下文，不需要 state |
| **Agent**（偷懒模式 / Pattern B） | 是 | 仅当人显式说「读 state.md 按 Next step 继续」 |

### Pattern B 的安全栏

如果 Agent 被指令读 state.md：

1. **必须先核对** `Next step.Agent` 与自己角色一致。不一致直接拒绝执行，告诉人「我不是这一步该上场的 Agent，你应该粘给 X」。
2. **必须扫 Blockers**。非空时不要直接执行，先让人确认阻塞已解除。
3. **不接管多步**——只执行 Next step 这一步，下一步仍由人接力。

Scout 国产模型对 Pattern B 的安全栏不一定靠谱，建议优先用 Pattern A。
