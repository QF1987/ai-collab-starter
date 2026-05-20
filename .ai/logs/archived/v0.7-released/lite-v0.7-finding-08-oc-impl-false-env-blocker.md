---
finding-id: lite-v0.7-finding-08-oc-impl-false-env-blocker
severity: P2
category: prompt + escalation-discipline-gap
source-project: smart-uite (bug-20260520-h5coat-tray-white-screen-qt5core-missing 03c round3)
discovered: 2026-05-20
target:
  - .ai/prompts/03-codex-orchestrate.md (03a 子任务包模板「测试要求」段必含项目标准执行入口 + 03c verify-don't-trust)
  - .ai/prompts/03b-opencode-impl.md (撞墙处理: 环境 blocker 必须用子任务包给定的标准入口验证过才能上报)
status: pending
related: [F07-v0.7]
---

# Finding F08-v0.7: OC-impl 报假环境 blocker (「不能执行, 你试一下」) 并把错误说法写进 progress.md

## 现象

smart-uite `bug-20260520-h5coat-tray-white-screen-qt5core-missing` epic 03c 第 3 轮, OC-impl 回复:

```
测试结果
VM 命令无法从 macOS 执行——SSH 到 Windows VM (192.168.2.149/7/77.7) 均不可达。
3 条 VM 命令已在 .ai/progress.md 中记录, 待 Human 在 Windows VM 执行。
```

但项目标准的 Windows VM 执行入口根本不是 SSH, 而是 `prlctl exec "Windows 11" --current-user ...` (Parallels)。Codex 03c **没有采信** OC-impl 的「不可达」说法, 直接用标准入口实测, 一次跑通 (X:\ redline FAIL + C:\ tray PASS 全部取得)。

更糟: OC-impl 把「VM 不可执行」这个**错误说法写进了 `.ai/progress.md`**, 由 Codex 后续纠正。

## 影响

- **假 blocker 险些卡死流程**: 若 Codex 采信「SSH 不可达」, 这个 P0 epic 会停在「待 Human 在 VM 执行」, 实际上标准入口完全可用。生产环境若 Codex 也不熟标准入口, 就真卡了。
- **审计文件被污染**: progress.md 是 append-only 审计流水, OC-impl 把未经证实的环境判断写进去, 留下错误历史记录。
- **根因是契约缺口, 不是 OC-impl 个体问题**: 子任务包没告诉 OC-impl「VM 命令怎么跑」, OC-impl 自己猜了 SSH, 猜错。

## 根因

### Gap 1: 03a 子任务包没给项目标准执行入口

`03-codex-orchestrate.md > 03a 子任务包模板`「测试要求」段只写「必须跑通命令: `<test cmd>`」, 没要求 03a 把**项目标准的执行环境入口** (e.g. `prlctl exec` / docker exec / 特定 runner) 显式写进去。OC-impl 在独立 session, 不带项目环境知识, 撞到 cross-OS 执行就自己猜。

### Gap 2: 03c 没有「verify-don't-trust」纪律

`03-codex-orchestrate.md > 03c` 收到 OC-impl「不能执行 / 环境不可达」类 blocker 时, 没有强约束要求 Codex **先用标准入口自己验证一次**再决定是否采信。本次是资深 Codex 主动不采信, 纯靠经验。

### Gap 3: 03b 允许把未验证的环境判断当结论上报

`03b-opencode-impl.md > 撞墙处理` 没区分「真撞墙」vs「我不知道怎么跑」。OC-impl 把「我不会跑」包装成「环境不可达」事实, 还落档 progress.md。

## 证据

- smart-uite `bug-20260520-h5coat-tray` 会话归档 §6: OC-impl 原话「SSH 到 Windows VM 均不可达」; Codex 判断「没有采信 SSH 说法, 使用项目标准入口 prlctl exec」, 随后 3 条 VM 实测全部跑通。
- 同 §6 扣分点: 「OC progress 中保留了『VM 不可执行』的错误说法, 由 Codex 纠正」。

## 提议修复

### 1. `03-codex-orchestrate.md > 03a 子任务包模板`「测试要求」加标准执行入口

```markdown
### 测试要求
- 必须跑通命令: `<test cmd>`
- (v0.7 · F08-v0.7) 若测试需在非本机环境跑 (Windows VM / 容器 / 远程 runner),
  03a 必须把**项目标准执行入口命令原文**写进本段, e.g.
  `prlctl exec "Windows 11" --current-user cmd /c "..."`。
  禁止只写「在 VM 上跑」让 OC-impl 自己猜入口。
```

### 2. `03-codex-orchestrate.md > 03c` 加 verify-don't-trust 纪律

```markdown
(v0.7 · F08-v0.7) 03c 收到 OC-impl「不能执行 / 环境不可达 / SSH 失败」类 blocker 时,
不直接采信。必须先用子任务包给定的标准执行入口自己验证一次:
- 标准入口确实跑通 → OC-impl 报的是假 blocker, 03c 按实测结果继续, 并要求 OC-impl 修正 progress.md 错误记录
- 标准入口也失败 → 才是真环境 blocker, 升 Human
```

### 3. `03b-opencode-impl.md > 撞墙处理` 区分真撞墙 vs 不会跑

```markdown
(v0.7 · F08-v0.7) 环境类 blocker (命令跑不起来 / 环境不可达) 上报前, 必须先确认:
- 已用子任务包「测试要求」段给定的标准执行入口尝试过
- 未给标准入口 → chat 输出「子任务包未给 <环境> 执行入口, 需 Codex 补」, 不要自己猜 SSH/其它入口当事实
禁止: 把「我不知道怎么跑」写成「环境不可达」事实, 更禁止写进 progress.md。
```

## SemVer 影响

**MINOR** (03a/03c/03b 各加纪律子句 · 不破坏 v0.6 旧子任务包 · 纯增量约束)。

## 关联

- 与 F07-v0.7 同 epic (`h5coat-tray`) 同轮 (03c round2/round3) 触发, 一组处理。
- 与 v0.6 F06 (Codex direct-solve mode) 弱关联: 都是「OC 产出不可信时 Codex 兜底」, F08 是更轻量的 verify-don't-trust, 不到脱编排程度。

---

## v0.7 实施记录 (2026-05-20)

本 finding 在 `v0.7.0-lite-rc1` release 消化。实施详情见 `CHANGELOG.md` `[v0.7.0-lite-rc1]` 段。
