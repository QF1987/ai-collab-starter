# starter-v3 Finding #20: P1 #2 dogfood — v2.0 三步法在 Small task 上的适配评估

- Created: 2026-05-14
- Reporter: OpenCode (04-opencode-review)
- Scope: `.ai/prompts/04-opencode-review.md`(v2.0) 在 Small task(≤30 行/单文件)的适用性

---

## F-A: 三步法模板读起来像在审 Epic

**发现**: v2.0 04 prompt 的「第二步 · Architecture 对齐」使用 ADR Decision/L1-L5 Data Contract 术语与 escalation 流程——对 7 行的 header 补丁过度武装。实际执行时 reviewer 快速跳过 ADR 段、手工映射 task AC 做逐条核对（AC1-AC6），这是正确的，但模板本身暗示的评审深度远大于任务需要的。

**影响**: 后续 Small task reviewer 可能被模板引导去搜索不存在的 ADR、构造无意义的 escalation，浪费时间。

**建议**: starter v3.0 新增「Small task review 简化模板」（见下文 Recommendation 段），仅要求 scope + AC + 测试三检，不跑完整三步法。Epic/Normal task 仍用现有三步法。

**Severity**: P3（模板话术问题，不影响本次 review 正确性）

---

## F-B: 后端 E2E 证据要素对跨仓 client/backend 形态的适用性

**发现**: v2.0 04 prompt 第三步入「常规审视」部分（第 52 行）的检查清单（N+1 风险 / try-with-resources / 字段语义滥用等）偏向 Java/Spring 后端场景。本次 client 侧 Kotlin/Android 改动 7 行，不涉及任何后端 pattern。

Codex 没提供 DB 烟测证据是合理的——task AC6 标注「手工烟测」且 progress.md 明确说未跑。后端 go test PASS 是有效的回归验证。client 侧 gradle test PASS 也成立。

**建议**: 04 prompt 第三步的 Quality 常规项改为「repo 自适应」——根据改动文件后缀 / 语言自动选择检查项（Kotlin → null safety/时序/测试 / Go → -race/N+1/资源关闭）。不必在 04 里实现，纳入 starter v3.0 design note。

**Severity**: P3（设计建议，不阻塞）

---

## F-C: state.md 自动生成 vs 人手增强 prompt 详细度

**发现**: Codex 自刷的 `Next step.可粘贴 prompt` 为 6 行，涵盖角色、任务、输入、产出。Human 在本轮加的增强版为 19 行（含具体 check list + 分支路径 + gradle 命令 + commit message 模板）。

对比:

| 维度 | Codex 自动版 | Human 增强版 |
| --- | --- | --- |
| 行数 | 6 行 | 19 行（超软目标 10 行） |
| ACL 完整度 | 仅角色指向 | 含 Expected fix 原文 + 测试命令 |
| 分支逻辑 | 无 | 无（PATCH 无分支） |
| 可复用模板度 | 高（纯指针） | 中（任务特定细节偏多） |

**建议**: starter v3.0 模板化时应取「Codex 指针版 + 固定 3 字段」（输入文件路径 / Expected fix ID / 验证命令），不重复 task 文件已有内容。`state.md` prompt body 硬上限 15 行维持不变。Human 不想丢细节时把细节搬进 `.ai/tasks/<task>.md > Fix guidance` 段。

**Severity**: P3（模板设计讨论，不阻塞）

---

## Recommendation for starter v3.0

在 `04-opencode-review.md` 头部加 Small task 分流：

```markdown
### Small Task Shortcut（≤30 行 / 单文件、无 architectural change）

满足 Small task 条件时**跳过完整三步法**，只执行：

1. Scope 验证（文件数/行数/路径匹配）
2. AC 逐条核对（用 task 文件 Acceptance Criteria 表逐条打 ✅/❌）
3. 测试证据检查（gradle test / go test / cargo test 输出片段必须出现在 progress.md）
4. 一条常规检查：grep 全仓调用点（有遗漏记 P2）

Small task review 输出简化 verdict:
- PASS → state.md Next step = Human merge
- PATCH → state.md Next step = Codex fix（single round）
- REJECT → state.md Next step = Claude（escalation）

Small task review **不**需要 ADR alignment / ADR Data Contract L1-L5 / GitNexus impact 结果 / commit 状态检查（Small task 默认已 commit）。
```

不修改三步法原文（保留供 Epic/Normal task 使用），只加快捷键。
