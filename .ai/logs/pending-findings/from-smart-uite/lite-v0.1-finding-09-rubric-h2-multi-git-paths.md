---
finding-id: lite-v0.1-finding-09-rubric-h2-multi-git-paths
severity: P2
category: rubric + prompt
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/oc-code-quality-rubric.md (H2 paths 二组分 验证段)
  - .ai/prompts/03b-opencode-impl.md (Scope 强约束段)
  - .ai/prompts/03-codex-orchestrate.md (03c 验收流程)
status: pending
related: [01]
---

# Finding 09: rubric H2 paths 验证在 umbrella + 子 git 多 git 场景含糊 — git diff 该在哪跑?

## 现象
lite [`oc-code-quality-rubric.md`](.ai/oc-code-quality-rubric.md) H2 (paths 二组分) 验证方法:
```
git diff --cached --stat, 逐行核对每个文件路径都在子任务包 paths 列表内
```

03b prompt > Scope 强约束:
```
git diff --cached --stat
逐行核对每个文件路径都在子任务包 paths 内
```

**但**在 smart-uite 这种 umbrella git + 30 子 git 场景:
- OC-impl 改 `Daemon/Daemon.cpp` → 这个 diff 在 **Daemon 子仓** 的 .git 里, 不在 umbrella 顶层
- 顶层 `git diff --cached --stat` 在 umbrella git 跑 → 输出空 (umbrella 不追 Daemon/)
- 必须 `cd Daemon && git diff --cached --stat` 在子仓跑

rubric / prompt 没说 cwd 是哪个 git, OC-impl 可能误以为"umbrella git diff 空就是 scope 干净", 漏过越界改动。

## 影响
- 严重风险: OC-impl 在 umbrella 跑 git diff 看到空, 以为没改任何 paths 外文件, 实际改了 Daemon/ 内 paths 外的 X.cpp 没被检测
- Codex 03c 也按 H2 同样命令验证, 同样的盲区
- OC-review 04 第一步 Scope 验证也按 git diff 走, 同样盲

## 根因
rubric H2 + 03b/03c/04 prompt 都假设**单 git 场景**, 没考虑 umbrella + 子 git 拓扑。

## 证据
- 本对话尚未跑到 03b (T2 OC-helper 进行中), 但这个盲区会在 03b 实施期暴露
- finding 01 (umbrella git scenario) 是上游问题 (文档无说明), finding 09 是下游 (rubric/prompt 自身在多 git 场景下行为含糊)

## 提议修复

### 1. **`oc-code-quality-rubric.md` H2 重写**:
```markdown
- [ ] **H2**. paths 二组分: OC-impl 只动了"核心 paths" + 子任务包明确许可的"连带 paths"
  - 验证方法 (依 git 拓扑分场景):
    - **单 git 场景**: `git diff --cached --stat` 在主仓跑, 逐行核对
    - **umbrella + 子 git 场景** (e.g. smart-uite): 子任务包 paths 列表必须按"绝对路径或 <子仓相对路径>/<文件>"格式; 验证时
      1. 在 umbrella 顶层跑 `git diff --cached --stat`, 核对追踪 paths (通常仅 .ai/ AGENTS.md)
      2. 对每个涉及的子仓: `cd <子仓> && git diff --cached --stat`, 核对子仓内 paths
      3. 若 OC-impl 改了未列子仓的文件 → H2 fail
    - **跨仓场景** (e.g. $REPO_MAIN + $REPO_X): 在每个 repo cwd 内跑 git diff, 分别核对各 repo paths
  - 典型 fail 信号: 改了未列子仓的文件 (e.g. 子任务包只列 Daemon/, 但 diff 显示 MsgTransManager/ 也改了)
```

### 2. **`03b-opencode-impl.md` > Scope 强约束** 改成同样的"分场景跑":
```
改动后、测试前, 跑 (依 git 拓扑分场景):
- 单 git: `git diff --cached --stat` 在主仓
- umbrella + 子 git: 在 umbrella 跑 + 在每个改动子仓 cd 进去跑
- 跨仓: 每个 repo 各自跑
```

### 3. **`03-codex-orchestrate.md` 03c 验收**: 验收前先确认 git 拓扑, 按场景跑 H2

### 4. **子任务包 paths 列表格式硬约束** (Codex 03a 输出时):
```
单 git 场景: paths 用相对仓根路径 (src/foo.go)
umbrella + 子 git 场景: paths 必须用 "子仓名/相对路径" (Daemon/Daemon.cpp), 让 H2 能识别该跑哪个子仓 git diff
```

## SemVer 影响
**MINOR** (rubric H2 / 多 prompt 改成分场景, 新增能力; 单 git 场景行为不变)。
