---
finding-id: lite-v0.1-finding-07-unconfirmed-reproduction-discipline
severity: P2
category: doc + prompt
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/getting-started.md (§三 差异 1 Bug Brief 模板)
  - .ai/prompts/02-codex-plan.md (bug 任务专属强约束段)
status: implemented-in-v0.2.0-lite-rc1
related: []
---

# Finding 07: bug 复现路径未确认场景的纪律没说 — "先摸排再写 Decision, 不能先猜根因"

## 现象
本次 smart-uite Daemon 单例 bug, Bug Brief Reproduction 段我写 "**复现路径未确认**, 以下任一可能触发 (4 条嫌疑), 待 L2 摸排 + 复现验证"。这是合理的, 因为用户反馈 "守护进程启可以启动多个" 但没说怎么触发的。

lite `getting-started.md §三 差异 1 Bug Brief 模板` 默认假设 Reproduction 段"必须能让别人按这个 repro 出来", 没说**复现路径未确认时**怎么办:
- 是不是该停下让 Human 先复现?
- 还是写"嫌疑路径列表" + L2 摸排去验证?
- Codex 02 在这种 brief 上跑出来的 Decision 段算可信吗?

我的处理: 在 brief 加了 "**复现要求 (修复必带)**" 段 + Codex 02 提示词要求 Decision 段含 "先复现再修" 流水 (第 1 步识别 ≥ 1 条复现 / 第 2 步 测试 pre-patch fail / 第 3 步 patch / 第 4 步 post-patch pass)。但这套也是 ad-hoc。

## 影响
- 复现未确认就跑完 02-03, OC-impl 修一个猜测的根因, OC-review 没办法验证 (没 repro 路径), Human merge 后用户反馈 "bug 还在", 浪费一轮
- bug 修复整个流程信任崩塌

## 根因
`getting-started.md §三 差异 1` Bug Brief 模板 Reproduction 段只写:
```
## Reproduction
<具体步骤、命令、输入、环境>
<必须能让别人按这个 repro 出来>
```
没说 "若复现未确认, 怎么办"。

`02-codex-plan.md` 没 bug 任务专属强约束 (只有通用 7 条)。

## 证据
- 本对话 Step 1 Bug Brief 草稿, 我即兴加 "Reproduction 复现路径未确认 + 4 条嫌疑" + "复现要求 (修复必带)" 段
- 本对话 Step 2 T1 Codex 02 提示词, 我即兴加 "Decision 段必须明确'先复现再修'流水"
- 这两套 ad-hoc 跑出效果好, 但没沉淀到 lite

## 提议修复
1. **`getting-started.md` §三 差异 1 Bug Brief 模板 · Reproduction 段** 加规则:
   ```markdown
   ## Reproduction
   <若已确认: 具体步骤、命令、输入、环境, 别人能按这个 repro 出来>
   <若未确认: 标"复现路径未确认", 列 ≥ 2 条嫌疑触发路径, 标"待 L2 摸排 + 复现验证">
   ```
2. **`getting-started.md` §三 差异 3 实施必须带回归测试** 加新条:
   ```markdown
   - [ ] 若 Reproduction 标"未确认", 03b 必须先 L2 复现验证 (至少 1 条嫌疑路径变成 confirmed), 才能进 03c 验收
   ```
3. **`02-codex-plan.md`** 加新段 "## bug 任务专属强约束 (v0.2.0)":
   ```
   bug 任务在通用 7 条强约束之上, 额外要求:

   ### B-1. 复现路径处理 (Reproduction 段)
   - 若 Reproduction = "已确认" → 标准流程
   - 若 Reproduction = "未确认 + N 条嫌疑" → 触发 L2 摸排强制路径:
     - 不能直接出 Decision, 必须先让 OC-helper + GitNexus 把嫌疑 N 条收敛到 confirmed ≥ 1 条
     - 02 brief 末尾必须含 "复现验证产出" 段, 列具体复现脚本路径 + pre-patch 测试预期 fail 行为
     - 03c rubric D3 + 04 OC-review 第三步必须验证 "revert patch 后测试确实 fail"

   ### B-2. 修复策略三选 (Decision 段)
   - minimal patch / refactor-with-fix / defer + workaround 三选一明确
   - 紧急 P0 默认 minimal + workaround

   ### B-3. pre-decisions 锁定 (bug 专属)
   - 必含: "回归测试: pre-patch fail / post-patch pass" 验证流水
   - 必含: "不顺手 refactor 相邻代码"
   - 必含: "改动范围限定 Affected subprojects"
   ```

## SemVer 影响
**MINOR** (新增 02-codex-plan bug 任务专属强约束段, 旧通用流程不变)。

---

## v0.2.0-lite-rc1 实施记录 (2026-05-18)

- **release**: v0.2.0-lite-rc1
- **触发来源**: smart-uite epic (Daemon 单例 bug, commit 9afc2f7) 实战 dogfood 反馈 — lite v0.1 首次真实大型项目接入
- **实施摘要**: 见 `CHANGELOG.md > [v0.2.0-lite-rc1]` 段, 本 finding (F07) 落入对应分组 (group A/B/C/D/E/F/G), 详见 CHANGELOG `### Why these changes` 段
- **关联 commit**: 见 `git log --oneline v0.1.0-lite-rc1..v0.2.0-lite-rc1` (release 提交 hash 由 Step 6 tag 后填入)
- **archive 路径**: `.ai/logs/archived/v0.2-released/lite-v0.1-finding-07-unconfirmed-reproduction-discipline.md`
