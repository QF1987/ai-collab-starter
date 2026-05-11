# Session State

> Resume 协议。每个 Agent 完成后必须刷新本文件。
> 下一次开 session 第一件事：读这里就知道接哪一步。
>
> 与 `progress.md` 区别：progress 是流水账（追加），state 是当前快照（覆盖）。

## Active task

- 当前 task: `NONE`
- 当前阶段: `NONE`
- 起始时间: `NONE`

## Last completed step

- Agent: `NONE`
- Step: `NONE`
- 完成时间: `NONE`
- Commit: `NONE`
- 产出: `NONE`

## Next step

- Agent: `NONE`
- Prompt 模板: `NONE`
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
- 启动新任务建议用 `/intake` skill（Claude Code）或读 `.ai/intake-templates.md`（OC/Codex）。

---

## 维护规则

1. 每次 Agent 完成时**覆盖**本文件（不是 append）；旧快照已在 `progress.md` 流水账里。
2. `Next step` 的可粘贴 prompt 必须由 Agent 在自己的 `## 下一步提示词` 段产出后**抄进**这里。
3. session 中断后回来——**默认 Pattern A**：你（人）用眼读本文件 → 复制 `Next step.可粘贴 prompt` → 粘给对应 Agent。Agent **不读** state.md（它收到的 prompt 已自带完整上下文）。
4. 任务整体完成（merge + 文档收口都做完）：清空 `Active task / Last completed step / Next step`，仅保留 `Notes` 给下个任务参考。
5. 多个并行任务：本文件**只**追当前活跃任务；其它任务用各自的 task 文件 `Handoff state` 段记录。

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

OpenCode 国产模型对 Pattern B 的安全栏不一定靠谱，建议优先用 Pattern A。
