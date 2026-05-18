---
finding-id: lite-v0.3-finding-05-subtask-package-must-not-override-03b-contract
severity: P2
category: prompt + doc
source-project: lite-self (v0.3.0-lite-rc1 dogfood · smart-uite daemon-business-manager-not-started bug 03b 阶段)
discovered: 2026-05-18
target:
  - .ai/prompts/03-codex-orchestrate.md (03a 子任务包模板 加"必做段不能 override 03b 契约" 硬约束 + 子任务包模板示例段移除可能 override 03b 的常见违例项)
  - .ai/prompts/03b-opencode-impl.md (收尾必做段 加显式优先级"03b 契约 > 子任务包必做段")
  - .ai/oc-code-quality-rubric.md (H1 验证段补 "子任务包是否含 override 03b 契约的必做项" 检测)
  - .ai/prompts/04-opencode-review.md (3b 自审盲点 加 B8 "子任务包必做段 override 03b 契约" 检测)
status: pending
related: [F02, F14]
---

# Finding F05-self: 03a 子任务包"必做"段可 override 03b prompt 硬约束 (本次 dogfood OC-impl 被误导刷了 state.md)

## 现象

smart-uite v0.3.0-lite-rc1 dogfood (daemon-business-manager-not-started bug, 03b 阶段):

`03b-opencode-impl.md > 收尾必做` 段明确硬约束:
```
### **不**刷 state.md, **不**写"下一步提示词"

lite 中 OC-impl 是被调度者, 不是调度者。state.md 由 Codex 03c 刷, 下一步由 Codex 决定。
```

但 Codex 03a 拆 OC-impl 子任务包时, "实施要求 > 必做" 段第 4 条写:
```
4. 在 .ai/progress.md 追加 03b 执行记录占位/结果记录, 在 .ai/state.md 刷到 03b-impl 完成后等待 Codex 03c 的下一步提示。
```

OC-impl 严格执行子任务包"必做"段, **刷了 state.md** (Last completed step.Agent=OC-impl, Step=03b-impl-1, 完成时间, 产出, Next step 全段都被 OC-impl 填):
- 违反 03b prompt "收尾必做" 硬约束 (不刷 state.md)
- 副作用: Next step.Prompt 模板 引用了不存在的文件 `.ai/prompts/03c-codex-verify.md` (实际契约是 `.ai/prompts/03-codex-orchestrate.md > 03c 段`), OC-impl 没读 03 contract 文件名, 凭推断填错路径

## 影响

- **OC-impl 不知道该听谁**: 子任务包"必做"段 vs 03b prompt 契约**直接冲突**时, 当前 lite 没明确优先级。OC-impl 默认遵循"具体输入 (子任务包) > 通用契约 (03b prompt)" 是符合人类直觉的, 但破坏 lite 设计的"职责分离" (OC-impl 不刷 state, Codex 调度)
- **Codex 03a 写"必做"段时无防错栏**: 没有任何 prompt / rubric / review checklist 检测"子任务包必做段是否 override 03b 契约", Codex 03a 自由发挥, 可能 silently 让 OC-impl 越权
- **副作用扩散**: 本次副作用是 Next step.Prompt 模板 ref 错路径, 下次可能更严重 (e.g. 03a 必做让 OC-impl 写 ADR / 改 review.md 等 03b 不该做的事)
- **lite Pattern A 失效**: state.md 字段值变得不可信 (OC-impl 填的字段反映 OC-impl 视角而非 Codex 调度视角), Pattern A "Human 读 state.md 接力" 信任度下降

## 根因

`03-codex-orchestrate.md > 子任务包模板` (lite v0.2+) 当前结构:
```
## 实施要求 (严格按下方执行, 任何偏离请输出原因不要自作主张)
### 必做
1. ...
2. ...
```

"必做" 段开放式, 没列禁止项 (不能让 OC-impl 做 X / Y / Z)。Codex 03a 自然倾向把"完成后该做什么" (含刷 state.md / 写下一步提示词) 都写进必做, 不知道这些是 03b 契约**禁止**给 OC-impl 做的事。

`03b-opencode-impl.md > 收尾必做` 段 "**不**刷 state.md" 硬约束**只单向写**, 没说"若子任务包必做段要求刷 state.md 怎么办" (沉默 = 默认遵循子任务包?)。

`oc-code-quality-rubric.md > H1` (pre-decisions 无一条被违反) 不检测"子任务包是否含 override 03b 契约的必做项"。

`04-opencode-review.md > 3b Codex 自审盲点专项` B1-B7 不检测此项。

## 证据

- smart-uite `.ai/scratch/oc-impl-package-bug-20260518-daemon-business-manager-not-started-1.md` 第 24 行 "必做" 第 4 条 (Codex 03a 写)
- smart-uite `.ai/state.md` Last completed step.Agent = OC-impl, Step = 03b-impl-1, 全段 被 OC-impl 填 (违反 03b "不刷 state.md")
- smart-uite `.ai/state.md` Next step.Prompt 模板 = `.ai/prompts/03c-codex-verify.md` (不存在! 实际是 `.ai/prompts/03-codex-orchestrate.md > 03c 段`) — OC-impl 凭推断填错路径
- `03b-opencode-impl.md` lines 126-128: "**不**刷 state.md, **不**写'下一步提示词'" 硬约束

## 提议修复

### 1. **`03-codex-orchestrate.md > 03a · 子任务包模板`** 加 "必做段禁止项" checklist

```markdown
## 实施要求 (严格按下方执行, 任何偏离请输出原因不要自作主张)

### 必做 (Codex 03a 写本段时遵守 · v0.4 新增 F05-self)

**禁止把以下事项写入"必做"段** (这些是 03b 契约硬约束 OC-impl 不该做的事, 由 Codex 03c 刷 / 由其他 prompt 处理):

- ❌ 刷 state.md (是 Codex 03c 的活, 03b 契约第 X 行明确禁止)
- ❌ 写"下一步提示词" (是 Codex 03c 的活)
- ❌ 写 ADR / 改 .ai/decisions.md (是 Codex 02 的活)
- ❌ 写 review finding / 改 .ai/review.md (是 OC-review 04 的活)
- ❌ 跑 04 自审 / 翻 finding status (是 OC-review 04 的活)
- ❌ 决定下一个 epic / 拆新 task (是 Human + Codex 01-intake / 02 的活)
- ❌ append .ai/progress.md 跨 epic 总结 (本 epic 单条记录 OK, 但不能 closeout 收口)

**只允许把以下事项写入"必做"段**:
- ✅ 改具体业务代码文件 (paths 二组分内)
- ✅ 写测试 / 新增测试文件
- ✅ 跑测试命令验证 PASS
- ✅ 改 .ai/progress.md **当前 epic 单条执行记录** (e.g. "03b 完成 X 任务, 输出 Y")
- ✅ 改文档 (README / 注释) 在 paths 列表内

#### 必做段示例 (v0.4)
1. ✅ 把 `Daemon/config/Daemon.ini` 的 `DaemonName` 改为 `DcBusinessManager.exe`
2. ✅ 新增 `Daemon/test/X.ps1`, 含 P0-P5 检查链
3. ✅ 跑 `prlctl exec ... build.ps1` + `prlctl exec ... X.ps1`, 拿 PASS 证据
4. ✅ 在 `.ai/progress.md` 追加一条"03b 完成 X" 单行记录 (不收口本 epic)

❌ (v0.3 反例) 在 `.ai/state.md` 刷到 03b-impl 完成后等待 Codex 03c — **越界**, 03b 契约禁止
```

### 2. **`03b-opencode-impl.md > 收尾必做`** 加显式优先级

```markdown
### **不**刷 state.md, **不**写"下一步提示词" (v0.4 强化 F05-self)

lite 中 OC-impl 是被调度者, 不是调度者。state.md 由 Codex 03c 刷, 下一步由 Codex 决定。

**契约优先级 (v0.4 · F05-self)**: 
- 03b prompt 契约 > 子任务包"必做"段
- 若子任务包"必做"段含 "刷 state.md" / "写下一步提示词" / "写 ADR" / "改 review.md" 等 03b 禁止项, **OC-impl 必须忽略该必做项**, 在 chat 输出:
  ```
  ⚠️ 子任务包必做段第 N 条要求 <做 X>, 违反 03b prompt 契约 (不刷 state.md / ...) · 已跳过, 等 Codex 03c 修 03a 子任务包必做段
  ```
- 不要静默执行越权指令 (本次 dogfood OC-impl 静默刷 state.md 是 lite v0.3 失误)
```

### 3. **`oc-code-quality-rubric.md > H1`** 加子项

```markdown
- [ ] **H1**. pre-decisions (brief frontmatter) 无一条被违反
  - 验证方法: 对 frontmatter 每条 D 找 diff 中是否动了相关代码 / 接口 / 决策
  - 典型 fail 信号: D2 锁"不引入新依赖", OC-impl 在 package.json 加了 lodash
  - **(v0.4 · F05-self 新增) 子任务包必做段 override 03b 契约检测**:
    - 子任务包"必做"段是否含 "刷 state.md" / "写下一步提示词" / "写 ADR" / "改 review.md" / "跑 04 自审" 等 03b 禁止项 → H1 直接 fail, 退回 Codex 03a 重写子任务包必做段
```

### 4. **`04-opencode-review.md > 3b Codex 自审盲点专项 checklist`** 加 B8

```markdown
- [ ] **B8** (v0.4 · F05-self). 子任务包必做段是否 override 03b 契约
  - 验证方法: 读子任务包 (`.ai/scratch/oc-impl-package-*-N.md`) "必做" 段, 检查是否含 03b 禁止项 (刷 state.md / 写下一步提示词 / 写 ADR / 改 review.md / 跑 04 自审 / 跨 epic 总结)
  - 命中信号: state.md `Last completed step.Agent = OC-impl` 且填了完整字段 → OC-impl 越权刷了 state.md, 根因可能在 03a 必做段 override
  - 严重度: P2 (lite 系统级风险, Pattern A 信任度下降), 升 Human
```

## SemVer 影响

**MINOR** (新增契约优先级 + rubric H1 子项 + 04 B8 + 03a 必做段禁止项 checklist · 不破坏 v0.3 旧子任务包 · 旧子任务包必做段含越权项仍能运行只是 OC-impl 应主动跳过 + chat 警告 + Codex 03a 应回查修)。

## 关联与对照

- 与 **F02** (state.md 字段漂移) 同根: F02 是 condensed 字段, F05-self 是越权刷字段 (谁刷)。两者一起把 state.md 写权限纪律补全
- 与 **F14** (03a 子任务包落档) 弱关联: F14 让子任务包跨 session 可见, F05-self 让子任务包内容守契约边界
- 与 **F08** (B7 state.md 字段完整性) 协同: F08 catch 字段被 condensed, F05-self 通过 B8 catch 越权写; 两者一起 review 兜底 state.md 质量
- 与 **F04-self** (intake evidence ingestion) 同形态: 都是"契约盲区导致 Agent 个体行为不可预测"; 本次 dogfood 同时暴露
