---
finding-id: lite-v0.1-finding-14-03a-package-chat-only-no-file
severity: P2
category: prompt + doc
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/prompts/03-codex-orchestrate.md (03a 输出哪里段)
  - .ai/workflow.md (§8 共享文件协议段补 OC-impl 子任务包落档约定)
  - .ai/state.md (template Last completed step.产出 字段示例补"子任务包文件路径")
status: implemented-in-v0.2.0-lite-rc1
related: [02, 13]
---

# Finding 14: 03a OC-impl 子任务包只在 chat, 没必经文件中转, Pattern A 跨 session 重建不完整

## 现象
smart-uite Daemon bug 修复 03a 阶段, Codex 跑完后:
- state.md 写 "03a OC-impl 子任务包草案已生成"
- 但**实际子任务包正文只在 T1 Codex chat 历史里**, 没落任何文件 (`.ai/tasks/` / `.ai/scratch/` / state.md 都没正文)

lite `03-codex-orchestrate.md > 03a 输出哪里` 当前设计:
```
- 把每个子任务包**作为完整 code block 输出在 chat 里**, Human 复制粘贴到 T3
- 同时刷 state.md: Next step.Agent = OC-impl, Prompt 模板 = 子任务包 (而不是 03b-opencode-impl.md, 后者是 OC-impl session 的契约文件; 子任务包是具体输入)
- 收尾必做的"可粘贴 prompt"字段填**子任务包正文**
```

设计意图是"子任务包正文进 state.md `Next step.可粘贴 prompt` 字段", 但 smart-uite 实际跑出来这个字段写的是 **Human 审查 prompt** (因为用户在 Step 2 提示词里加了"跑完停下让 Human 审子任务包"约束), 子任务包正文反而漏了。

## 影响
1. **Pattern A 跨 session 重建失败**: T1 session 崩 / 被 clear → 子任务包丢失, 别的 Claude / Codex 再开 fresh session 读 state.md 也接不回来
2. **Human 审查不便**: Human 想离线审 / 转给别人看 / 多人协作时, 都拿不到正文
3. **审查痕迹不可追溯**: epic 收口回顾时想看"当时 03a 拆任务的颗粒度", 只能翻 T1 chat 历史, chat 也可能 clear
4. **辅助 Claude 审计场景**: 像本对话这种 Claude (我) 辅助审 03a 时, 没法 read 子任务包文件 — 这本对话亲自踩了这个坑

## 根因
- `03-codex-orchestrate.md > 03a 输出哪里` 段把 chat output 当唯一输出通路, **没强约束"同步落档到文件"**
- state.md `Next step.可粘贴 prompt` 字段是双重职责: 既是 prompt body, 又是子任务包 — 当中间插入 Human 审查 gate 时, 字段被 Human 审查 prompt 占用, 子任务包正文无落点
- workflow.md §8 共享文件协议只覆盖了 OC-helper req/out, 没覆盖 OC-impl 子任务包

## 证据
- 本对话 2026-05-18 00:55 Codex 03a 跑完, state.md `Next step.可粘贴 prompt` 是 "你是 Human。请审 ..." 审查 prompt, 不含子任务包正文
- 我 (Claude 辅助 session) 搜 `.ai/scratch/` + `.ai/tasks/` 都找不到子任务包文件, 只能让 Human 复制粘贴或让 T1 Codex 单独落档
- 这套救火流程本次跑成功, 但**应该是默认行为**, 不应 ad-hoc

## 提议修复

### 1. **`03-codex-orchestrate.md > 03a 输出哪里` 段重写为双输出强约束**:

```markdown
### 03a 输出哪里 (v0.2.0 双输出强约束)

每个 OC-impl 子任务包必须**双输出**:

1. **chat 输出** (Human 复制到 T3 OC-impl 用):
   - 完整 markdown code block, 子任务包模板见上方
   - 写在 chat 末尾, 加 `--- 子任务包结束 ---` 分隔符方便复制

2. **同步落档到文件** (Pattern A 重建 + Human 审 + 后续追溯用):
   - 路径: `.ai/scratch/oc-impl-package-<task-id>-<n>.md`
   - 内容: **chat 输出原文 1:1 同步**, 不允许任何文字差异
   - 文件首行: `# OC-impl 子任务包 <task-id>-<n>` 标题
   - 文件末尾追加: `## 落档说明` 段, 说明 chat 与文件内容一致

state.md 同步刷:
- `Last completed step.产出` 列子任务包文件路径
- `Next step.可粘贴 prompt`: 若 Next.Agent = OC-impl, 字段填子任务包正文 (chat 原文); 若 Next.Agent = Human (审查 gate), 字段填审查 prompt + **必须**在 prompt 中显式引用子任务包文件路径

禁止:
- chat 输出但不落档
- 落档但与 chat 不一致 (任何文字差异)
- 修订子任务包同时落档 — 这种情况应输出新版子任务包 (-2, -3 ...) 而不是 silent 改第一版
```

### 2. **`workflow.md > §8 共享文件协议` 补 OC-impl 子任务包文件**:

加新子段 §8.4:
```markdown
### 8.4 OC-impl 子任务包文件 (v0.2.0)

```
.ai/scratch/oc-impl-package-<task-id>-<n>.md  ← Codex 03a 写: OC-impl 子任务包正文
```

`.gitignore` 已含 `.ai/scratch/`, 子任务包默认不入版本控制 (临时文件, epic 结束 Human 可清空)。
若需归档审计追溯, epic 收口时 Human 把本轮所有子任务包 cp 到 `.ai/logs/archived/<epic-id>/` 保留。
```

### 3. **`state.md` template `Last completed step.产出` 字段示例**:

```markdown
- 产出: `NONE`

<!-- 产出字段填写约定:
     不要手写具体 finding 文件清单, 改写产出根目录 + "(数量请 ls 实查)"
     (v0.2.0 新增) 03a 阶段产出必含:
       - .ai/scratch/oc-impl-package-<task-id>-<n>.md (子任务包正文落档)
       - .ai/tasks/<task-id>.md Implementation slices 段更新 (若 paths 收紧)
-->
```

## SemVer 影响
**MINOR** (新增 03a 双输出强约束 · 改变 prompt 契约 · 不破坏 v0.1 旧产出 · 旧子任务包没落档的不算违规仅算 best practice 不达标)。

## 关联与对照
- 与 **Finding 02** (state.md 字段漂移) 关联: F02 修字段名, F13 修阶段枚举值, F14 修产出落档纪律 — 三者一起把 state.md 跨 session 完整性补全
- 与 **Finding 13** (state.md 阶段枚举漂移) 关联: F13 的 `03a-prep` / `02-plan-refine` 中间态扩展 + F14 的落档纪律, 共同覆盖"复杂 02-03 流转"场景

---

## v0.2.0-lite-rc1 实施记录 (2026-05-18)

- **release**: v0.2.0-lite-rc1
- **触发来源**: smart-uite epic (Daemon 单例 bug, commit 9afc2f7) 实战 dogfood 反馈 — lite v0.1 首次真实大型项目接入
- **实施摘要**: 见 `CHANGELOG.md > [v0.2.0-lite-rc1]` 段, 本 finding (F14) 落入对应分组 (group A/B/C/D/E/F/G), 详见 CHANGELOG `### Why these changes` 段
- **关联 commit**: 见 `git log --oneline v0.1.0-lite-rc1..v0.2.0-lite-rc1` (release 提交 hash 由 Step 6 tag 后填入)
- **archive 路径**: `.ai/logs/archived/v0.2-released/lite-v0.1-finding-14-03a-package-chat-only-no-file.md`

---

## main v5.1.0-rc1 处置 (2026-05-20)

**拒收 (lite 架构专属)** — 本 finding target 的 lite 专属文件 (oc-code-quality-rubric / oc-helper / 03a 拆包子任务包) 在 main 不存在; main 的 03 不拆包、无独立 rubric 文件。不适用 main。
