---
finding-id: lite-v0.1-finding-12-soft-conditional-loophole
severity: P3
category: prompt
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/prompts/02-codex-plan.md (§决策必须落到唯一具体选择 段)
status: implemented-in-v0.2.0-lite-rc1
related: []
---

# Finding 12: 02-codex-plan.md "禁止"清单未覆盖"或等价 / 仅当需要 / 若有必要 / 如有需要 / 视情况"软条件等价措辞

## 现象

smart-uite Daemon 单例 bug 02 brief 起草过程中, Codex 在 Decision / Implementation slices / OC delegation candidates 段有偏好用条件等价句 (e.g. "可选用 PID 文件 **或等价**机制", "**仅当需要**跨进程通知时再走 SendMessage", "**若有必要**可在测试侧补 .ps1 后备")。这些措辞在语法上看似明确, 实际把 trade-off 决策又推回 OC-impl, 跟 lite "Codex 决唯一具体选择" 设计冲突。

`02-codex-plan.md > 决策必须落到唯一具体选择` 段目前禁止清单只列了两类:
```
- 写「或」字给下游 OC-impl 选择 (如「设置 cancelled_at 或复用 FailedAt」)
- 写「让 OC-impl 决定」/「让实施者判断」/「视情况而定」
```

漏掉的软条件等价措辞:
- **或等价 / 或类似** (or-equivalent): "用 X 或等价机制" / "用 X 或类似 Y 的方案"
- **仅当 X 时 / 仅在 Y 场景** (conditional trigger): "仅当跨进程时再加锁" / "仅在 Win32 平台启用"
- **若有必要 / 如有需要** (if-needed): "若有必要可补单测" / "如有需要补 fixture"
- **按需 / 视情况** (on-demand · "视情况而定" 已禁但只覆盖完整短语, 未覆盖"按需"单字)
- **可考虑 / 可以选用** (suggestion language): "可考虑用 A 或 B"

这些措辞共性: **看似给了主导方案, 实际把"是否启用 / 用哪个等价 / 何时启用"的判断权下放**, 跟 §40-41 "或"字禁令同根, 应一并扩展。

## 影响
- 不严重 (P3) — 当前 Codex 出 brief 时即兴用了一次, 我 (Human) 当场指出改掉, 未真造成 03b 撞墙
- 但: lite 设计"force Codex 做 trade-off" 的核心约束在这层有漏洞。任意一句"可选 / 若需要 / 或等价"都让 brief 退化成模糊指令, OC-impl 收到后要么自己拍 (违反 lite 设计), 要么撞墙停 (浪费一轮)
- 与 F05 (alternatives UX 维度) 同根: 都是"Codex 不充分 force trade-off" 的不同形态

## 根因

`02-codex-plan.md` 第 36-50 行 "决策必须落到唯一具体选择" 段禁止清单不完整, 只覆盖了"或" + "视情况而定" 字面值, 未覆盖语义同类但措辞不同的软条件等价模式。

## 证据

- 本对话 2026-05-18 Codex 02 brief 起草过程, 我在审第一稿时即兴指出 "Decision 段含 '仅当需要时启用 X' 字样, 这是给 OC-impl 留口子, 改成 '本次启用 X · 理由: ...' 或 '本次不启用 X · 理由: ...'", Codex 改后第二稿这类措辞清零
- F12 之前 float 给 Human (跳号占位), 未落档 inbox; v0.2.0-lite 升级一并补落 + 一并修

## 提议修复

**`02-codex-plan.md > 决策必须落到唯一具体选择` 段** 禁止清单扩展为:

```markdown
每条决策**必须**给出**唯一具体实现选择**——禁止:

- 写「或」字给下游 OC-impl 选择 (如「设置 cancelled_at 或复用 FailedAt」)
- 写「让 OC-impl 决定」/「让实施者判断」/「视情况而定」
- (v0.2.0 新增) 写「或等价 / 或类似」(or-equivalent 措辞: "用 X 或等价机制" / "用 X 或类似 Y 的方案")
- (v0.2.0 新增) 写「仅当 X 时 / 仅在 Y 场景 / 仅当需要」(conditional-trigger 措辞: 把"是否启用"的判断推下游)
- (v0.2.0 新增) 写「若有必要 / 如有需要 / 按需」(if-needed 措辞: "若有必要可补单测" → 应直接 "本次补单测覆盖 X" 或 "本次不补单测 · 理由: ...")
- (v0.2.0 新增) 写「可考虑 / 可以选用」(suggestion 措辞: "可考虑用 A 或 B" → 应直接给胜出方案 + Alternatives 段列被拒方案)
- 把架构选择推给下游

如果你确实拿不准, **正确做法**是 (不变):
- 在 ADR `Alternatives considered` 段列出多个方案 + 你拒绝的理由
- 在 `Decision` 段给一个明确的胜出方案
- 在 `Follow-up` 段标「若实施时发现 X 假设错误, 回退此 ADR」

下游 OC-impl 看到 `Decision` 段必须能照着一条路走, 不需要再选。

### 反例 (dogfood 留底, v0.2.0)

❌ "可选用 PID 文件或等价机制保证单例" — 既"或" 又"等价", 双重模糊
✅ "本次用 Win32 CreateMutex 保证单例, 不走 PID 文件 · 理由: Daemon 是纯 Win32 程序, CreateMutex 是 OS 原语零依赖"

❌ "仅当跨进程通知时再走 SendMessage" — 把启用判断推给 OC-impl
✅ "本次启用 SendMessage 跨进程唤窗 · 理由: 用户体验需求 (已唤窗) 在 Decision 段已锁"

❌ "若有必要可补 .ps1 测试后备" — 是 OC-impl 写到撞墙了再补吗?
✅ "本次补 .ps1 测试后备 (路径 .../tests/daemon_singleton.ps1) · 不补 GTest · 理由: 本子项目无 GTest 基建, 改 CMakeLists 是 H2 越界"
```

## SemVer 影响

**PATCH** (现有禁止清单增量扩展, 不破坏 v0.1 旧 brief · 旧 brief 含"或等价 / 仅当"措辞仍合法, 只是不达 v0.2 best practice; 新 brief 必须 force 唯一具体选择)。

## 关联与对照

- 与 **F05** (alternatives UX 维度) 同根: 都是"Codex 不充分 force trade-off"; F05 修 alternatives 段缺维度, F12 修 Decision 段措辞软条件等价
- 与 **F14** (03a 子任务包落档) 弱关联: 02 brief 软措辞越多, 03a 子任务包就越容易翻译成"严禁动: 其余全部" 兜底 (F15)

---

## v0.2.0-lite-rc1 实施记录 (2026-05-18)

- **release**: v0.2.0-lite-rc1
- **触发来源**: smart-uite epic (Daemon 单例 bug, commit 9afc2f7) 实战 dogfood 反馈 — lite v0.1 首次真实大型项目接入
- **实施摘要**: 见 `CHANGELOG.md > [v0.2.0-lite-rc1]` 段, 本 finding (F12) 落入对应分组 (group A/B/C/D/E/F/G), 详见 CHANGELOG `### Why these changes` 段
- **关联 commit**: 见 `git log --oneline v0.1.0-lite-rc1..v0.2.0-lite-rc1` (release 提交 hash 由 Step 6 tag 后填入)
- **archive 路径**: `.ai/logs/archived/v0.2-released/lite-v0.1-finding-12-soft-conditional-loophole.md`
