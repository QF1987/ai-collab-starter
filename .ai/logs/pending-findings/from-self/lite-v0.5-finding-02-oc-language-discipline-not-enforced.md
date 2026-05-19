---
finding-id: lite-v0.5-finding-02-oc-language-discipline-not-enforced
severity: P3
category: prompt + doc + ux
source-project: lite-self (smart-uite daemon-dcbusinessmanager-error2 02-plan-refine 第 2 轮 OC-helper 完成后 Human 反馈)
discovered: 2026-05-19
target:
  - .ai/prompts/oc-helper.md (输出 chat 格式段加中文硬约束)
  - .ai/prompts/03b-opencode-impl.md (输出格式段同上)
  - .ai/prompts/04-opencode-review.md (输出格式段同上)
  - AGENTS.md template (Language Discipline 段加 lite framework 全局规则)
status: pending
related: [F11, F02-v0.5]
---

# Finding F02-v0.6: lite contract Language Discipline 在 OC 模型 (国产) 上不够强, 实战默认英文 chat 输出

## 现象

smart-uite v0.5.0-lite-rc1 sync 后 daemon-dcbusinessmanager-error2 epic 02-plan-refine 第 2 轮 OC-helper 跑完, **chat 输出全英文**:

```
out: .ai/scratch/oc-helper/out-bug-20260519-daemon-dcbusinessmanager-error2-2.md
status:
• find: 85 boost DLL paths across 4 pools (PublicFunction/boost, 3rdLibraries, entrancer/bin, recardbin/thirdparty/bin)
• source-vs-runtime: 0 missing, 33/33 matched, all byte-identical — boost_atomic IS on disk
• dumpbin: success — direct import [boost_json], transitive closure [boost_atomic, boost_json, boost_filesystem, boost_locale, boost_log, boost_thread]
• root cause: DLL search path issue, not file-missing. boost_atomic.dll resolved via entrancer.dll → boost_log.dll → boost_atomic.dll chain, but recardbin/thirdparty/bin not in Windows PE loader search path
• build rules: 6 key lines in StageTdmRuntime.cmake + 11 link-time refs found
total_matches: 85 + 6 + 17 = 108
done.
```

Human 反馈: "为什么 opencode 输出还是英文? 我需要输出默认中文".

## 影响

- **Human 阅读体验下降**: lite vs main 区别之一就是 lite 默认中文 (Pattern A Human bus 中文操作), 但 OC-helper 实战出英文 chat, Human 需翻译/猜测
- **跨 OC 模型行为不可预测**: OC 国产模型 (Kimi / Qwen / Doubao 等) 默认英文输出, lite contract 中文约束在 Token 策略段提了但不够强
- **AGENTS.md > Language Discipline 段** (smart-uite 项目级) 可能没明示 "lite framework 所有 Agent chat 输出默认中文", 全局规则缺失
- **跨 Agent 一致性问题**: Codex (CLI) 守约中文比较好; OpenCode (国产 OC) 不一定守; OC-impl / OC-review 也可能犯同样问题 (本次只在 OC-helper 触发, 但跨 epic 累积观察可能扩散)

## 根因

### Gap 1: `oc-helper.md > 输出 chat 格式` 段没强约束中文

当前段 (oc-helper.md):
```markdown
## 输出 chat 格式 (精简)

完成后, 在 chat 仅输出:

\`\`\`
out: .ai/scratch/oc-helper/out-<epic-id>-<n>.md
status: success | partial | failed
total_matches: <n>
done
\`\`\`
```

只规定**结构** (out/status/total_matches/done), 没规定**语言** (status 段 bullet 摘要 / done 之外的辅助说明用什么语言).

### Gap 2: Token 策略段中文要求覆盖不全

当前 (oc-helper.md > Token 策略):
```markdown
- **输出语言**: 中文 (notes 段) + 命令原始输出原样 (result 段)
```

只覆盖 **notes 段** (out 文件) + **result 段** (out 文件命令输出). 没覆盖 **chat 输出 status 段 / 摘要 bullet 点 / done 前的所有 chat 输出**.

### Gap 3: AGENTS.md > Language Discipline 没全局规则

derived 项目的 AGENTS.md 通常含 "Language Discipline" 段, 但 lite framework 在 derived 项目 bootstrap 时**没强约束加入** "lite framework 所有 Agent chat / 文件输出默认中文 (除 result 段命令原始输出例外)".

### Gap 4: 03b / 04 / 09-closeout 同根

03b-opencode-impl.md / 04-opencode-review.md / 09-codex-closeout.md 在 OC / Codex 模型上同样问题. 03b OC-impl 完成产出 "done, 见 git diff" 是英文短语; 04 OC-review chat 输出 finding summary 可能英文 (本次没明显触发, 但跨 epic 累积有风险).

## 证据

- smart-uite 2026-05-19 daemon-dcbusinessmanager-error2 02-plan-refine 第 2 轮 OC-helper chat 完整英文 (见上方现象段)
- 跨 epic 历史观察: 之前 dogfood OC-helper chat 偶尔混中英文, 但 Human 没显式反馈; 本次 user 反馈"我需要输出默认中文" 触发本 finding
- oc-helper.md Token 策略段 "输出语言" 行只列 notes 段 + result 段, 漏 chat 输出

## 提议修复

### 1. **`oc-helper.md > 输出 chat 格式`** 加中文硬约束

```markdown
## 输出 chat 格式 (精简 · v0.6 · F02-v0.6)

完成后, 在 chat 仅输出 (**chat 输出默认中文 · 命令原始输出 result 段例外原样**):

\`\`\`
out: .ai/scratch/oc-helper/out-<epic-id>-<n>.md
状态: success | partial | failed
total_matches: <n>
done.
\`\`\`

若需附加 status / notes 摘要 bullet (≤ 5 行), 必须中文表述 (e.g. "发现 33 个 boost DLL, 0 缺失" 而非 "find 33 boost DLLs, 0 missing").

只有 **req `action` 显式说明 `language: en`** 时才允许英文 chat 输出 (跨语言协作 / 国际化 review 等场景)。
```

### 2. **`oc-helper.md > Token 策略`** 段扩展

```markdown
- **输出语言** (v0.6 · F02-v0.6 强化):
  - chat 输出 (status / 摘要 / done 等所有非 result 内容): **中文默认**
  - notes 段 (out 文件): **中文默认**
  - result 段 (out 文件 grep / dumpbin / find 等命令原始输出): 原样保留 (不翻译)
  - 例外: req `action.language: en` 时允许英文 chat
```

### 3. **`03b-opencode-impl.md` / `04-opencode-review.md` / `09-codex-closeout.md`** 同步加中文硬约束

每个 prompt > 输出格式 段加 "**chat 输出默认中文**" 约束 (类似上述), 保证跨 Agent 一致性.

### 4. **AGENTS.md template** > Language Discipline 段加 lite framework 全局规则 (新文件 `.ai/AGENTS.md.template` 或 lite v0.6 升级仪式时同步)

```markdown
## Language Discipline (lite framework default · v0.6 · F02-v0.6)

lite framework 所有 Agent (Codex / OC-helper / OC-impl / OC-review) chat 输出 + scratch 文件 / state.md / progress.md / brief / review.md 等元数据 **默认中文**.

例外 (允许原样英文):
- 命令原始输出 (grep / dumpbin / find / git log 等)
- 代码片段 / 路径 / 符号名 / SQL 关键字 / 工程术语
- req.action.language: en 显式声明跨语言协作场景

国产 OC 模型 (Kimi / Qwen / Doubao 等) 实战可能默认英文, Human 喂 prompt 时若发现, 显式加 "chat 输出请用中文" 临时覆盖 + 升级 v0.X 时 force contract.
```

## 临时解 (v0.5-rc1 / 不升 v0.6 即可用)

Human 喂 OC-helper / OC-impl / OC-review prompt 时, 在 prompt 末尾**显式加一句**:

```
⚠️ chat 输出请用中文 (status 段 / notes 段 / 摘要 bullet 点都用中文, 命令原始输出 result 段原样保留)
```

不是 v0.5 contract 一部分, 但实战可用.

## SemVer 影响

**PATCH** (现有 prompt 输出格式段增量加中文硬约束 · 不破坏 v0.5 旧 chat 输出 · 旧英文 chat 仍合法但不达 v0.6 best practice; AGENTS.md template 加全局段是文档新增, 不破坏 derived 项目)。

## 关联

- 与 **F11** (v0.2 · OC-helper 默认过滤第三方) 弱关联 — 都是 OC-helper 实战 contract gap, F11 修过滤逻辑, F02-v0.6 修输出语言
- 与 **F02-v0.5** (OC-helper 默认 exclude .ai/scratch) 同形态 — 都是 OC-helper contract 在国产 OC 模型上行为差异 force
- 跨 epic 历史: 之前 dogfood 没显式 catch (Human 容忍中英混杂 chat), 本次 user 显式反馈 → 推动 v0.6 contract 改进
- 关联 v0.6 整体 Language Discipline 加强 (跨 Codex / OC 模型一致性)
