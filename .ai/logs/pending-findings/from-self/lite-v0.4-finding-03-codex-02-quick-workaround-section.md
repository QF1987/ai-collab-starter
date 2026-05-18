---
finding-id: lite-v0.4-finding-03-codex-02-quick-workaround-section
severity: P3
category: prompt
source-project: lite-self (v0.4.0-lite-rc1 dogfood · smart-uite dcbusinessmanager-h5coat-start-fails bug 02 P0 gate 阶段)
discovered: 2026-05-18
target:
  - .ai/prompts/02-codex-plan.md (输出格式末尾加 "Quick workaround" 段 · P0/P1 必填)
status: pending
related: [F01-v0.5, F12, F06]
---

# Finding F03-v0.5: Codex 02 brief 缺 "Quick workaround" 应急路径段, P0 时 Human 不知道有 hotfix 选项

## 现象

smart-uite v0.4.0-lite-rc1 dogfood (dcbusinessmanager-h5coat-start-fails P0 bug 02 P0 gate 阶段, 2026-05-18):

Codex 02 plan finalize 给出完整 Decision + 4 alternatives + ADR:
- **Decision (选定)**: A · 改代码, 缺省 `StartH5Bit/Type32Bit` 走 32 位
- **Alt-1 拒**: B 编 64 位 H5Coat
- **Alt-2 拒**: C 默认包加 ini
- **Alt-3 拒**: UX 暴露用户选项
- **Alt-4 拒**: workaround 现场手动改 ini

Human P0 gate 阶段问 Claude: "Codex 没问我选哪个方案? 比如手动改配置文件还是改代码?"

→ 暴露真实需求: **Human 实际想要 quick path** (本机改 `dcCardDriver.ini` 加 `StartH5Bit/Type32Bit=true` 立即解锁) **同时不放弃长期代码修复**。

→ 但 Codex 02 brief 把 workaround 列在 "Alt-4 被拒", Human 容易理解为"绝对不要", **不知道可以作为应急路径同时跟长期 fix 并行**。

→ Claude 解释后 Human 才知道"hotfix 应急 + lite 流程长期 fix" 可双路并行。

## 影响

- **P0 时刻 Human 默认错过立即解锁机会**: 不知道有 quick workaround, 等 lite 流程 1-2 小时跑完才能用 (实际 30 秒能 hotfix)
- **生产线上事故 / 阻塞用户场景 Human 体验差**: 真实 P0 时 Human 优先想"现在怎么让用户能用", 其次才是"长期怎么修". Codex 02 brief 只给长期 fix, 不给应急路径
- **Alternatives 段语义混淆**: "被拒方案" 跟 "可作为应急 hotfix 的 workaround" 是两个语义, 当前 brief 把它们混在一起, Human 理解成本高
- **lite 设计意图 partial 失效**: lite 强调 "Codex force trade-off + Pattern A Human 接力", Pattern A 接力时 Human 应该看到所有可选 action (含应急), 当前 brief 没全展示

## 根因

`02-codex-plan.md > 输出格式` 当前段:
- Decision (唯一具体)
- Rationale
- Alternatives considered (≥ 2 个被拒方案 + 拒绝理由)
- Pre-decisions
- Compatibility and rollout
- Implementation slices
- Required tests
- Review focus
- OC delegation candidates
- Decision record (ADR-YYYYMMDD-NN)

**漏**: "Quick workaround" 应急路径段 — 给 Human 一条"现在能跑的 ≤ 30 秒 hotfix" 命令, 跟长期 fix 并行。

P0/P1 严重度任务尤其需要 — 用户线上阻塞时, 1-2 小时不可接受。

## 证据

- smart-uite 2026-05-18 H5Coat-start-fails 02 P0 gate 阶段 Human 问"怎么选 quick path vs 改代码"
- Claude 解释后 Human 才知道可双路并行 (10 秒 hotfix + lite 流程长期 fix)
- 类似真实场景: daemon-business-manager-not-started epic 第 1 轮 VM stuck 时, Human 也是问 "VM 我清不了怎么办", Claude 给重启 VM 命令解锁 — 也是应急 path 没在 brief 里, 靠 Claude 现场指引

## 提议修复

**`02-codex-plan.md > 输出格式`** 末尾加新段:

```markdown
## Quick workaround (P0/P1 必填 · P2/P3 可选 · v0.5 · F03-v0.5)

> 给 Human 一条**现在能跑的 ≤ 30 秒 hotfix**, 跟 lite 流程长期 fix 并行.
> P0/P1 必填, P2/P3 可显式标 "无 quick workaround, 直接等 lite 流程修复".

- **应急命令 / 操作**: <≤ 30 秒能跑完的具体步骤; e.g. "在本机 `dcCardDriver.ini` 加 `StartH5Bit/Type32Bit=true`">
- **适用范围**: <仅本机 / 仅当前安装包 / 仅 dev VM / ...>
- **与 Decision 关系**: 跟长期 fix (Decision 段方案) 不冲突, 可并行
- **为什么这不是 Decision**: 引用 Alternatives `Alt-N · workaround · 被拒` 段, 解释"作为唯一修复不够" (e.g. 无法覆盖新机器 / 重装包 / 配置重生成 / 多设备), 但**作为应急 OK**
- **执行人**: Human (lite contract: workaround 不走 OC-impl, Human 直接跑)
```

### Pre-decisions 协同 (P0/P1)

P0/P1 bug 任务 frontmatter 应加新 pre-decision (D-extra):

```yaml
pre-decisions:
  ...
  - D-quick: Human 在 P0 gate 阶段必须看 Quick workaround 段, 决定是否并行跑 hotfix
```

### 04 OC-review B10 自审盲点协同 (v0.5)

```markdown
- [ ] **B10** (v0.5 · F03-v0.5). P0/P1 bug 任务 02 brief 是否含 Quick workaround 段
  - 验证方法: `grep -q '^## Quick workaround' <brief>` (P0/P1 任务必有, 否则 fail)
  - 命中信号: P0/P1 brief 无该段, 应升 Human 重审 02 (Codex 02 偷工)
  - 例外: 该段标 "无 quick workaround" 显式声明 OK
  - 严重度: P3 (UX 优化, 不阻塞)
```

## SemVer 影响

**MINOR** (新增 02 输出格式段 + frontmatter D-quick + 04 B10 · 不破坏 v0.4 旧 brief · 旧 brief 无 Quick workaround 段仍合法, 只是 v0.5 新 brief P0/P1 必须含)。

## 关联与对照

- 与 **F01-v0.5** (Assumptions to verify by Human) 同形态: 都是 P0 / 严重度 brief 应主动 force Codex 给 Human 必读信息 (前者是 cross-check 信息, 后者是应急 action 信息)
- 与 **F12** (软措辞清单) 弱关联: F12 防 Codex 02 给模糊决策, F03-v0.5 让 Codex 02 给清晰的"应急路径 vs 长期 fix" 二分
- 与 **F06** (severity → escalation 默认映射) 协同: P0/P1 触发 `human-escalation-suggested: true` + Quick workaround 段, Human gate 看 brief 一眼知道(a)接受 (b)退回 (c)override + 是否并行 hotfix
- 触发本 finding 的实战是 v0.4 dogfood, lite 自演化路径
