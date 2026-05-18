---
finding-id: lite-v0.1-finding-10-bug-regression-test-revert-verify
severity: P3
category: prompt + rubric
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/prompts/03b-opencode-impl.md (bug 任务专属段)
  - .ai/oc-code-quality-rubric.md (D3 测试质量)
  - .ai/prompts/04-opencode-review.md (Small Task Shortcut + 三步法)
status: implemented-in-v0.2.0-lite-rc1
related: [07]
---

# Finding 10: bug 任务 03b/03c/04 没强调 "先 revert patch 验证 fail" 这套测试纪律

## 现象
bug 修复的回归测试有特殊要求: **不只是测试 PASS, 还要测试在 patch 前 reliably FAIL** (证明测试真覆盖了 bug 代码路径)。但 lite 现有:

- `03b-opencode-impl.md` 没 bug 专属段, OC-impl 写完测试 PASS 就当 done
- `oc-code-quality-rubric.md` D3 (测试质量) 评分标准 "happy path / 边界 / 错误路径", 没 bug 专属 "revert patch 必须 fail" 验证
- `04-opencode-review.md` 三步法第三步 quality / Small Task Shortcut, 没 bug 专属 review

[`getting-started.md §三 差异 3`](.ai/getting-started.md) Bug Acceptance Criteria 已经写:
```
- [ ] 回归测试: 复现脚本 / 单测能在 patch 前 fail、patch 后 pass
```

但这是 task 文件 AC 段, **prompts 没把 AC 这条 enforce 到 03b/03c/04 流程里**, OC-impl/Codex/OC-review 容易漏 enforce。

## 影响
- OC-impl 写测试就为 PASS, 测试可能根本没跑 bug 代码路径 (e.g. mock 了关键函数让测试 trivially 过)
- Codex 03c 看测试 PASS 就 H3 ✅, 不验 "revert 后 fail"
- OC-review 同盲
- bug 修复后用户反馈"bug 还在", 因为测试是假测试

## 根因
lite 把 bug 任务专属纪律放在 getting-started.md §三 (Human 写 brief 时看), 但**没下沉到 03b/03c/04 prompt 自身**, 跨 step 流转时易丢失。

## 证据
- 本对话 Step 1 Bug Brief 草稿我加了 "## 复现要求 (修复必带)" 段, 列了"patch 前 N 个 Daemon, patch 后只能 1 个"流水
- 本对话 Step 2 T1 Codex 02 提示词加了 "Decision 段必须明确'先复现再修'流水"
- 这些 ad-hoc 都靠 Human 在每一步手动加, 没沉淀到 prompt 自身
- finding 07 (复现路径未确认) 解决 "complete brief" 层面; finding 10 解决 "实施期 enforce" 层面

## 提议修复

### 1. **`03b-opencode-impl.md` 加新段 "## bug 任务专属 (v0.2.0)"**:
```markdown
若子任务包标记 task 为 bug 类型 (frontmatter `severity: P0-P3`), 在标准 03b 流之上额外要求:

1. **测试必须先写, 后改代码** (TDD-for-bug):
   - 写复现测试 / 单测, 跑一次, 确认 FAIL (复现 bug)
   - 改业务代码
   - 重跑测试, 确认 PASS
2. **完成产出加证据**:
   - 输出 "done, 见 git diff" 之外, chat 加一段:
     ```
     ## bug 测试两阶段证据
     pre-patch (测试单独 + 主代码旧): <test cmd> 输出 FAIL <关键断言失败行>
     post-patch (测试 + 主代码新): <test cmd> 输出 PASS
     ```
3. **若不能两阶段验证** (e.g. 测试与主代码原子提交分不开), 必须在 chat 标"两阶段证据不可分", Codex 03c 决定是否退回拆 commit
```

### 2. **`oc-code-quality-rubric.md` D3 加 bug 专属子项**:
```markdown
| **D3. 测试质量** | 0 (fail) | 1 (差) | 2 (合格) | 3 (好) |
| ... | 无/假测试 | 只 happy path | + 1-2 边界 | + 错误路径 |
| (bug 任务) | + 测试本身存在但无证据 revert patch 后 fail | 测试存在 + 假装 fail (没真跑 pre-patch) | 测试存在 + chat 有两阶段证据 | 测试存在 + 两阶段证据 + revert 自动化测试 (CI 跑) |
```

### 3. **`04-opencode-review.md > 三步法第三步 3a · 通用 quality`** 加 bug 专属一条:
```
- [ ] **bug 任务专项**: 若 task 是 bug, 检查 chat 历史 / progress.md 是否有"pre-patch fail / post-patch pass"两阶段证据
  - 命中信号: 只有 post-patch PASS, 无 pre-patch FAIL 证据 → 测试可能假, 升 Human
```

### 4. **`04-opencode-review.md > Small Task Shortcut`** 加: "bug 任务**不**适用 Small Task Shortcut, 因为 bug 任务必须跑完整三步法验证回归测试有效性"

## SemVer 影响
**PATCH** (现有 prompt 加 bug 专属段, 不破坏其他任务流程)。

---

## v0.2.0-lite-rc1 实施记录 (2026-05-18)

- **release**: v0.2.0-lite-rc1
- **触发来源**: smart-uite epic (Daemon 单例 bug, commit 9afc2f7) 实战 dogfood 反馈 — lite v0.1 首次真实大型项目接入
- **实施摘要**: 见 `CHANGELOG.md > [v0.2.0-lite-rc1]` 段, 本 finding (F10) 落入对应分组 (group A/B/C/D/E/F/G), 详见 CHANGELOG `### Why these changes` 段
- **关联 commit**: 见 `git log --oneline v0.1.0-lite-rc1..v0.2.0-lite-rc1` (release 提交 hash 由 Step 6 tag 后填入)
- **archive 路径**: `.ai/logs/archived/v0.2-released/lite-v0.1-finding-10-bug-regression-test-revert-verify.md`
