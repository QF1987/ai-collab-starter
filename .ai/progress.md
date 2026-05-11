# Progress

> 流水账：每个 Agent / 每次 session 的实际进展。**追加式**（不覆盖）。
>
> 与 `state.md` 区别：state 是当前快照（最新），progress 是完整历史。
> Agent 完成时**必须**追加一段；不写无法回溯。

## 段落格式

```markdown
## YYYY-MM-DD HH:MM — <简短标题>

- Owner: <Agent / Human>
- Step: <一句话描述本步骤>
- 产出: <文件路径列表 / commit hash>
- 验证: <命令 + 结果>
- 已知风险: <bullet 列表，无则省略此项>
- 下一步: <交给谁、做什么>
```

## 归档约定

progress.md 超过 ~500 行后跑 `scripts/archive-progress.sh` 归档旧段落到 `.ai/archive/YYYY-MM.md`。

```bash
bash scripts/archive-progress.sh --keep-days 30   # 保留最近 30 天，其余按月归档
```

归档不丢失内容，只让活跃文件保持轻量便于 Agent 读取。

## Token 消耗记录约定

每段 Agent 输出末尾应含一行 token 消耗记录（参考 `.ai/prompts/0*.md` 收尾段）：

```
Tokens: in=<n> out=<n> total=<n>
```

每月末跑一次汇总：哪个 Agent / 哪类任务 token 消耗最高，作为下季度 prompt 优化输入。

---

<!-- Agent 追加新段落开始 -->
