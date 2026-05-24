---
finding-id: starter-v5.2-finding-26-state-md-must-not-bloat
severity: P2
category: template (state.md 维护规则)
source-project: DeviceOps
discovered: 2026-05-24
target:
  - .ai/state.md(template 维护规则段加第 6/7 条)
  - .ai/prompts/02-claude-plan.md / 03-implement.md / 04-review.md(收尾段补 prompt body 行数自检)
status: pending
related: [02]
---

# Finding 26: state.md 维护规则需加「state ≠ progress」红线 + prompt body 行数自检

## 现象

DeviceOps M3-Beta S3 阶段,Claude 刷新 state.md 时:
- **Next step.可粘贴 prompt body = 84 行**(starter 02-claude-plan.md 硬上限 = 15 行)
- **Last completed step.摸排发现段**复制了 context packet 的 R1-R7 全文(packet 本身已有)
- **Notes 段**「S3 共享文件分工纪律」「cellular_seeding + max_upload_kbps reserved」各重复出现 2 次
- **关键复盘归档 3 条**常驻 state.md(应放 epic-level lessons 文件)
- **Token 消耗 in≈178000** 历史统计塞进 Last completed step(应在 progress.md)

总行数 175,合理快照应在 80 行内。整改后 88 行(prompt body 12 行)。

## 影响

- Pattern A 人 read 时干扰极大(找不到 resume 关键信息)
- Pattern B Agent read 时 token 黑洞
- 跨 session resume 时,「快照」失去「最小 resume 信息」本意,退化为「滚动日志」
- Finding #02(lite v0.1)已发现「state.md 字段被简化漂移」,本 finding 是其镜像:**字段反向膨胀漂移**

## 根因

starter v5.1.0 `.ai/state.md` template 有 5 条维护规则:
1. 覆盖式刷新(已防 append 漂移)
2. Next step prompt 从 Agent `## 下一步提示词` 段抄入
3. Pattern A vs B 协议
4. 任务完成清空字段
5. 多任务用 task 文件 Handoff State

**缺**:
- ❌ 第 6 条「**state ≠ progress**」红线:Agent 容易把 packet 详情、token 统计、复盘内容塞进 state.md
- ❌ 第 7 条「prompt body 行数自检」:`02-claude-plan.md` 写了 15 行硬上限,但**没在 state.md template 里 cross-reference**,Claude 刷 state.md 时不会主动想起这条约束

## 证据

- DeviceOps `.ai/state.md` 整改前 175 行(commit history 可查 git)
- 整改后 88 行(L4 整理后),Next step prompt body 12 行
- 整改对比详见 `DeviceOps/.ai/logs/M3-B-starter-dogfood-2026-05-24.md > 问题清单`
- 实战教训:Claude 04-review 阶段在 review prompt 里把 9 条审查重点全塞 state.md 也撞同样问题

## 提议修复

### 1. `.ai/state.md` template 维护规则段追加第 6 / 7 条

```markdown
6. **state ≠ progress 红线**:本文件只承载「resume 所需的最小快照」。详细 R1-Rn 摸排发现、token
   统计、prompt drafting 备忘、epic 教训复盘等**全部放别处**(packet / progress.md / lessons),
   state.md 留指针即可。
   - ❌ 反例:把 context packet 的 R1-R7 全文 copy 到 Last completed step.摸排发现
   - ✅ 正例:`- 产出: .ai/logs/<packet>.md(R1-R7 全覆盖); 关键校正 1 行指针`

7. **Next step 可粘贴 prompt body 硬上限 15 行**(对齐 02-claude-plan.md 收尾段约束)。
   超过说明任务定义不清,应把详细信息搬进 task / packet / ADR,prompt 只承担「指向 + 启动」。
   - 自检:每次写完 Next step prompt 后 `wc -l` 数一下 fence 内行数
```

### 2. `.ai/prompts/02-claude-plan.md / 03-implement.md / 04-review.md` 收尾段

收尾段已有「刷新 state.md」要求,补一行 cross-reference:

```markdown
- 刷新 state.md 时,**严守第 6 / 7 条维护规则**(state ≠ progress 红线 + Next step prompt body
  ≤ 15 行)。检查清单见 state.md 头部。
```

## 优先级建议

- P2 = 中优先;实战已多次撞坑(本 epic S2 / S3 阶段连续两次)
- lite v0.7.x state.md 模板同步加这两条
