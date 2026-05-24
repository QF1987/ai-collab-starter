---
finding-id: starter-v5.2-finding-27-progress-archive-autocheck
severity: P2
category: AGENTS.md(收尾必做)+ 各 prompt 收尾段
source-project: DeviceOps
discovered: 2026-05-24
target:
  - AGENTS.md(收尾必做段加 progress.md 行数自检)
  - .ai/prompts/03-implement.md / 04-review.md / 06-fix.md(收尾段自检清单)
status: pending
related: []
---

# Finding 27: progress.md 行数自检触发 archive 提示(scripts/archive-progress.sh 现有但从未触发)

## 现象

DeviceOps 用 starter v5.0+ 约 18 个月,`scripts/archive-progress.sh` 始终存在(May 10 创建),
**但从未被任何 Agent 触发**。直到 2026-05-24 由人工 audit 发现 `progress.md` 已涨到 **3038 行
(111 时间戳章节)**,远超 CLAUDE.md「~500 行 archive」软阈 6 倍。

执行 `bash scripts/archive-progress.sh --keep-days 3` 后 progress.md 从 3038 → 1258 行,
1782 行归档到 `.ai/archive/2026-05.md`(零数据丢失,文件还有规范 header)。

## 影响

- 每次 session 启动 Scout / Impl / Claude 若顺手读 progress.md → token 黑洞(3000+ 行历史)
- Pattern A 人 read state.md 后若想 dig 历史 progress,被 3000+ 行海洋淹没
- archive 脚本工具齐备但触发机制空缺 → 所有用 starter 的项目都会撞同样问题(类比 #25 协议外漂移
  无人挡 → 全项目漂移)

## 根因

starter 现状:
- ✅ `scripts/archive-progress.sh` 工具完备(切段 / 按月归档 / dry-run 支持)
- ✅ CLAUDE.md 类项目级文档**可能**写「~500 行 archive」(但不强制)
- ❌ **AGENTS.md 收尾必做段**没列 progress.md 行数自检
- ❌ **各 prompt 收尾段**(02/03/04/05/06)没列 archive 触发器
- ❌ 没有任何 hook / reminder 让 Agent 主动 `wc -l .ai/progress.md`

结果:工具有人写,但没人记得用。

类比:`scripts/starter-status.sh` 有 inbox 监控功能,但若没有 `getting-started.md` 写明「session
开头主动检查」,工具也会沉睡 — starter 已经在 #02/#26 等场景验证过「工具 ≠ 触发,触发要靠协议」。

## 证据

- DeviceOps `progress.md` archive 前 wc -l = 3038
- archive 后 wc -l = 1258(留 54 段),归档 57 段到 `.ai/archive/2026-05.md`
- archive 脚本 commit:`/Users/qf/Alcedo/code/DeviceOps/scripts/archive-progress.sh`(May 10 创建)
- 18 个月零触发证据:`.ai/archive/` 目录在 audit 前不存在(`ls /Users/qf/Alcedo/code/DeviceOps/.ai/archive/` 报 No such)

## 提议修复

### 1. `AGENTS.md > 收尾必做` 段追加

```markdown
### progress.md 行数自检(v5.2.x · Finding #27)

每个 Agent(02/03/04/05/06)收尾**刷 state.md 前**,自检 progress.md 行数:

```bash
wc -l .ai/progress.md
```

- **< 500 行**:无需操作
- **≥ 500 行**:在 state.md `Notes` 段加一行提醒(不强制本次跑 archive,避免阻塞 epic 进度):
  `- progress.md 已 N 行,建议下个 epic 切换前跑 bash scripts/archive-progress.sh --keep-days 7`
- **≥ 2000 行**(严重超阈):**本次必须**跑 `bash scripts/archive-progress.sh --keep-days 7`
  归档后再刷 state.md;不归档不结束 session
```

### 2. `.ai/prompts/{02,03,04,05,06}-*.md` 收尾段统一加 cross-reference

```markdown
- 刷 state.md 前先按 AGENTS.md「progress.md 行数自检」执行(`wc -l .ai/progress.md`)
```

### 3. (可选,P3 范围)`scripts/starter-status.sh` 加 progress.md 行数监控

类似现有 inbox pending 数监控,加一行 `progress-lines: <N>`,超阈值时输出黄色 warning。

## 优先级建议

- P2 = 中优先;实战已撞坑(本 epic 18 个月零触发)
- 单纯修文档 + 加自检 bash 行,无破坏性
- lite v0.7.x AGENTS.md 同步加
