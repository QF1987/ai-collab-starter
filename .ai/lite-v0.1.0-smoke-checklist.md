# lite v0.1.0 Smoke 验收清单

> **状态**: 准备就绪, 待 Human 跑 4 终端 smoke (2026-05-16)
>
> **关系**: 本文件是 `.ai/lite-v0.1.0-design.md > §9` 的可执行版本, 实施 session 在 Phase 5 落下。
> 跑通后, Human 把结果回填本文件末尾"实跑结果"段, 决定 Phase 6 是否 release。

---

## A · 静态门槛 (实施 session 已落, 无需 Human 重跑)

按 `.ai/lite-v0.1.0-design.md > §9` 验收 10 项:

- [x] 1. 4 个新/改 prompt 文件落地: `02-codex-plan.md` / `03-codex-orchestrate.md` / `03b-opencode-impl.md` / `oc-helper.md`
- [x] 2. 02-codex-plan.md 强约束 7 条全文落地 (`§5 强约束 7 条` 段, 含 alternatives ≥ 2 / Data Contract L1-L5 / Negative consequences 不空 / pre-decisions ≥ 3 / paths 二组分 / 锁名前 grep 同包预检 / OC delegation candidates)
- [x] 3. `oc-code-quality-rubric.md` 文件存在, Codex 03c prompt (`03-codex-orchestrate.md > 03c · 验收`) 显式引用了它
- [x] 4. `04-opencode-review.md` 三步法第三步 3b 段含 Codex 自审盲点专项 checklist (B1-B6)
- [x] 5. `state.md` template 触发来源 lite 3 类 (A · pre-declared / C · OC escalation / H · 重试上限), 无 Claude 残留
- [x] 6. `lite-upgrade-protocol.md` 7-step Human 主导版完整 (从 starter-upgrade-protocol git mv + 全文 lite 化)
- [x] 7. CHANGELOG v0.1.0-lite 段写明 fork from main v4.0-rc1 + breaking diffs + ACP 否决记录
- [ ] **8. 共享文件协议 smoke** (T1/T2 两终端实跑) — **§B 待 Human 跑**
- [ ] **9. 完整 epic smoke** (4 终端齐用) — **§C 待 Human 跑**
- [x] 10. 经验回流协议在 lite-upgrade-protocol.md 引用 §8

打勾 8/10。剩 #8 #9 需 Human 在 4 终端环境跑。

---

## B · 共享文件协议 smoke (T1 + T2, ~10 min)

### 目的

验证 `.ai/scratch/oc-helper/` req/out 文件交换流程, 不引入业务代码改动。

### 步骤

#### Step 1 · 准备空 scratch 目录

```bash
cd ~/Alcedo/code/ai-collab-starter-lite
mkdir -p .ai/scratch/oc-helper/
ls .ai/scratch/oc-helper/   # 应为空
```

#### Step 2 · 开 2 终端

- **T1**: codex
- **T2**: opencode (任意国产模型也行, 跑 OC-helper 角色)

#### Step 3 · 在 T1 (Codex) 喂启动 prompt

```
你是 Codex (lite v0.1.0 lead engineer)。这是 §B 共享文件协议 smoke。
请写一个 OC-helper request 文件到 .ai/scratch/oc-helper/req-smoke-1.md,
让 OC-helper 全仓 grep 一下本仓 .ai/prompts/ 下所有 "pre-decisions" 出现位置。
req 文件按 .ai/prompts/oc-helper.md > req 文件格式 段写。
然后输出 "请让 OC-helper 跑 .ai/scratch/oc-helper/req-smoke-1.md"。
```

Codex 应输出一个完整 req 文件内容, 写到 `req-smoke-1.md`, 末尾输出请求。

**验证 1**: `cat .ai/scratch/oc-helper/req-smoke-1.md` 内容含 `intent` / `action: grep` / `pattern: pre-decisions` / `output_file: .ai/scratch/oc-helper/out-smoke-1.md`。

#### Step 4 · 在 T2 (OC-helper) 喂 prompt

```
你是 OpenCode, 按 .ai/prompts/oc-helper.md 契约执行。
读 .ai/scratch/oc-helper/req-smoke-1.md, 按里面 action 执行,
结果写到 output_file 指定路径。
```

OC-helper 应跑 `grep -rn "pre-decisions" .ai/prompts/`, 写 out 文件, chat 输出 `done` + status。

**验证 2**: `cat .ai/scratch/oc-helper/out-smoke-1.md` 内容含 `status: success` + `total_matches: <数字>` + result 段每行一个 `path:line | snippet`。

#### Step 5 · 回 T1 (Codex)

```
OC-helper 跑完了。
```

Codex 应自动读 `.ai/scratch/oc-helper/out-smoke-1.md`, 解析结果, 在 chat 中给出结论 (e.g. "确认 pre-decisions 在 02-codex-plan.md / 03-codex-orchestrate.md / 03b-opencode-impl.md / oc-helper.md / 04-opencode-review.md 出现, 共 N 次")。

**验证 3**: Codex 报告的总数 == out 文件 `total_matches` 字段值。

### Smoke pass 标准

- ✅ T1 写 req 成功, 格式遵守 oc-helper.md 模板
- ✅ T2 写 out 成功, status / total_matches / result 三段齐全
- ✅ T1 读 out 后给出正确结论
- ✅ 整个流程 Human 切终端次数 ≤ 4 (T1→T2→T1, 加上 T1 起步)

### Smoke fail 候选模式

| 现象 | 可能原因 | 处理 |
|------|---------|------|
| Codex 在 T1 直接跑 grep 不写 req | prompt 没强调 "写 req 不直接跑" | 改 02-codex-plan.md 触发边界段措辞 |
| OC-helper 在 chat 输出长结果不写 out | OC 训练倾向 chat 输出 | 改 oc-helper.md 加 "禁止 chat 长输出" |
| OC-helper 写 out 但 status 漏 | 模板段落理解偏差 | 改 oc-helper.md out 文件格式段 |
| Codex 读 out 后还重新跑 grep | Codex 不信任 helper 结果 | 改 02 prompt 强约束 "信任 helper 输出" |

---

## C · 完整 epic smoke (4 终端 + throwaway 业务, ~30 min)

### 目的

验证完整 02 → 03a → 03b → 03c → 04 → Human merge 流水,跑 4 终端协同 + Human bus + rubric 验收。

### 准备:throwaway 业务

不动 lite 仓自己代码, 起一个 throwaway 项目:

```bash
mkdir /tmp/lite-smoke-hello
cd /tmp/lite-smoke-hello
git init
mkdir -p .ai/scratch/oc-helper .ai/tasks .ai/logs
# 复制 lite kit 到该目录
rsync -av --exclude='.git' --exclude='.ai/scratch' \
  ~/Alcedo/code/ai-collab-starter-lite/.ai/ .ai/
cp ~/Alcedo/code/ai-collab-starter-lite/AGENTS.md .
# 初始化最小 Node 项目 (业务无关, 只是给 OC-impl 有地方写代码)
cat > package.json <<'EOF'
{
  "name": "lite-smoke-hello",
  "version": "0.0.1",
  "scripts": { "test": "node --test test/" }
}
EOF
mkdir -p src test
git add . && git commit -m "init: lite-smoke-hello throwaway"
```

### Task: "add hello endpoint"

把下面写到 `.ai/tasks/E1-hello-endpoint.md`:

```markdown
---
task-id: E1-hello-endpoint
size: Small
human-escalation-suggested: false
skip-review: false
created: 2026-05-16
---

# Task: 加一个 hello endpoint (smoke 用)

## What
在 src/server.js 加一个最小 HTTP server, GET /hello 返回 {"msg": "world"}。

## Why
lite v0.1.0 smoke 验证 4 终端 + rubric 流程。

## Acceptance hint
`npm test` 能跑通 1 个测试: GET /hello 返回 200 + JSON {"msg": "world"}。

## Known constraints
- Node 内置 http 模块, 不引入 express
- 单文件 src/server.js + 单测 test/server.test.js
```

### 步骤

#### Step C.1 · 开 4 终端

```bash
cd /tmp/lite-smoke-hello
tmux new -s lite-smoke
# Ctrl-B " 然后 Ctrl-B % 几次, 4 panes:
#   T1: codex
#   T2: opencode (OC-helper, 按需启动)
#   T3: opencode (OC-impl)
#   T4: opencode (OC-review)
```

#### Step C.2 · T1 Codex 02-plan

T1 喂:
```
你是 Codex (lite v0.1.0)。按 .ai/prompts/02-codex-plan.md 契约执行。
读 .ai/tasks/E1-hello-endpoint.md, 出 task brief (强约束 7 条全落)。
输出到 .ai/tasks/E1-hello-endpoint.md 末尾"# Architecture Plan" 段(覆盖 brief 原文不动)。
```

Codex 应输出 brief 含 alternatives ≥ 2 (e.g. express vs http 模块) + pre-decisions ≥ 3 + paths 二组分 + OC delegation candidates。

**Smoke 关键检查 #1**: brief frontmatter `pre-decisions` ≥ 3 条, alternatives 段 ≥ 2 个被拒方案。

#### Step C.3 · T1 Codex 03a 拆任务

T1 继续(同 session):
```
请进 03a, 按 .ai/prompts/03-codex-orchestrate.md > 03a 段, 把本 brief 拆成 OC-impl 子任务包。
小任务 (单文件实现 + 单测), 1 个子任务包足够。
输出完整子任务包 markdown 在 chat, Human 复制到 T3。
```

#### Step C.4 · T3 OC-impl 03b 写代码

T3 (新 session) 喂:
```
你是 OpenCode, 按 .ai/prompts/03b-opencode-impl.md 契约执行。
<粘贴 Codex 03a 输出的子任务包正文>
```

OC-impl 应写 src/server.js + test/server.test.js, 跑测试, 输出 "done, 见 git diff"。

**Smoke 关键检查 #2**: OC-impl 是否守 paths (无 package.json 改动除非允许 / 无其它文件改动)。
**Smoke 关键检查 #3**: OC-impl 是否在 chat 输出"我做了 X / Y / Z"长总结 (违反契约), 还是简洁 "done, 见 git diff"。

#### Step C.5 · 回 T1 Codex 03c 验收

T1 继续(同 02/03a session):
```
OC-impl 完成, 请按 .ai/oc-code-quality-rubric.md 验收。
跑 git diff 看改动, H1-H5 + D1-D8 打分。
```

Codex 应给出完整验收报告, 含每维度具体证据 + 总分。

**Smoke 关键检查 #4**: Codex 03c 报告每个维度有具体证据 (不是"OK" 一字过)。

假设通过 (16/24+):

#### Step C.6 · T4 OC-review 04

T4 (**必须**新 session) 喂:
```
你是 OpenCode, 在 T4 跑独立 review。按 .ai/prompts/04-opencode-review.md 三步法 + Codex 自审盲点专项执行。
本次 task: .ai/tasks/E1-hello-endpoint.md
变更: git diff 给的 src/server.js + test/server.test.js
跑完输出 findings markdown。
```

OC-review 应跑三步法, 输出 .ai/review.md。

**Smoke 关键检查 #5**: OC-review 是否执行 Codex 自审盲点专项 (B1-B6) checklist, 并显式标命中/未命中。

#### Step C.7 · Human merge

假设 OC-review PASS:
```bash
cd /tmp/lite-smoke-hello
git add . && git commit -m "feat: add hello endpoint (lite smoke E1)"
```

### Smoke pass 标准

5 个关键检查全过:

- ✅ #1 brief 强约束 7 条遵守 (尤其 alternatives ≥ 2 / pre-decisions ≥ 3)
- ✅ #2 OC-impl 守 paths
- ✅ #3 OC-impl chat 输出契约 (无长总结)
- ✅ #4 Codex 03c 给具体证据 (不是"OK"过)
- ✅ #5 OC-review 跑了 Codex 自审盲点专项

加 4 个流程检查:

- ✅ #6 4 终端齐用, Human 切终端次数有记录(预期 6-10 次/单 slice)
- ✅ #7 state.md 在每个 step 后正确刷新 (Last completed step.Agent 流转 Codex → OC-impl → Codex → OC-review → Human)
- ✅ #8 测试 PASS (`npm test` 通过)
- ✅ #9 review.md 有正式 finding 段(即使是 "无 P0-P3 finding, scope 干净")

### Smoke fail 候选模式

| 现象 | 可能原因 | 处理 |
|------|---------|------|
| Codex 02 alternatives 段敷衍 ("X 不好" 抽象拒绝) | 02 prompt 措辞不够强 | 改 02-codex-plan.md §强约束 1 段 |
| OC-impl 一次过 (第一轮 PASS, 不退回) | smoke 任务太简单, 看不出 rubric 效果 | 正常, 不算 fail |
| OC-impl 第一轮 fail, 第二轮 fail, 第三轮 PASS | 重试机制工作正常, 颗粒度合理 | 正常, 反而是好信号 |
| OC-impl 3 轮全 fail, 升 Human | 子任务包颗粒度太粗 | 把 throwaway 任务再细切, 或加强子任务包"必做"清单 |
| Codex 03c 验收时把 OC-impl 改动整个 revert | Codex 误解 rubric 退回模板 | 改 03-codex-orchestrate.md > 03c · 验收 段 |
| OC-review 把 OC-impl 完全否定 | session 隔离没起到效果, 或测试本身有问题 | 重看 04 prompt 三步法措辞 |

---

## D · 实跑结果 (Human 跑完回填)

### §B 共享文件协议 smoke

- 跑通日期: `<待填>`
- T1 写 req: ✅ / ❌
- T2 写 out: ✅ / ❌
- T1 读 out: ✅ / ❌
- 切终端次数: `<待填>`
- 异常: `<待填, 若无填 "无">`

### §C 完整 epic smoke

- 跑通日期: `<待填>`
- 5 关键检查:
  - #1 强约束 7 条: ✅ / ❌
  - #2 守 paths: ✅ / ❌
  - #3 chat 输出契约: ✅ / ❌
  - #4 03c 具体证据: ✅ / ❌
  - #5 Codex 自审盲点专项: ✅ / ❌
- 4 流程检查:
  - #6 4 终端齐用 / 切换次数: `<填数字>`
  - #7 state.md 刷新: ✅ / ❌
  - #8 测试 PASS: ✅ / ❌
  - #9 review.md 有 finding 段: ✅ / ❌
- 异常 / 意外现象: `<待填>`
- 触发 Human override 次数: `<待填, 预期 0>`
- 触发 3 轮 verify 上限次数: `<待填, 预期 0 或 1>`
- 总耗时: `<待填>`

### Phase 6 Go/No-go 决策

Human 看完 §C 结果:

- 9 项全过 → **Go**, 进 Phase 6 (commit + tag v0.1.0-lite, 不 push 等 Human 决定)
- 任 1 项 fail 但可 patch (改 prompt 措辞) → 修后重 smoke
- 多项 fail → No-go, lite 设计需 retro, 可能升 v0.1.0 → v0.1.0-rc2 / 退回设计文档

Human 决策: `<待填>`

---

## 附录 · 4 终端 tmux 速查

```bash
# 起 session
tmux new -s lite-smoke

# 分屏 (在 tmux 内按)
Ctrl-B "    # 水平分屏 (上下)
Ctrl-B %    # 垂直分屏 (左右)
Ctrl-B z    # 当前 pane 最大化/还原
Ctrl-B 方向键    # 切 pane
Ctrl-B ,          # 重命名 pane

# 推荐布局: 田字格 4 panes
# +-------+-------+
# | T1    | T2    |
# | Codex | Help  |
# +-------+-------+
# | T3    | T4    |
# | Impl  | Review|
# +-------+-------+

# detach: Ctrl-B d, 重连: tmux attach -t lite-smoke
```
