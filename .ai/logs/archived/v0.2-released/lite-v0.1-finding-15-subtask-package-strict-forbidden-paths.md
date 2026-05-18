---
finding-id: lite-v0.1-finding-15-subtask-package-strict-forbidden-paths
severity: P3
category: prompt + template
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/prompts/03-codex-orchestrate.md (03a 子任务包模板)
  - .ai/prompts/03b-opencode-impl.md (Scope 强约束段)
  - .ai/oc-code-quality-rubric.md (H2 验证段加"严禁动 paths"显式核对)
status: implemented-in-v0.2.0-lite-rc1
related: [09, 14]
---

# Finding 15: 子任务包"严禁动 paths"段应强约束 Codex 列具体高风险路径, 不是通用"其余全部"

## 现象
smart-uite Daemon bug 修复 03a 阶段, Codex 子任务包"上下文"段自创了一行:

```markdown
- 严禁动: `PublicFunction/`, `MsgTransManager/`, 其它 Dc*/Kit* 业务管家, `Daemon/CMakeLists.txt`
```

特别把 `Daemon/CMakeLists.txt` 显式列了 — 因为 OC-helper-2 摸排时建议"加 GTest 测试 (改 CMakeLists)" + "落 .ps1 后备 (不改 CMakeLists)" 两选, Codex 02 选了后者, 但 OC-impl 读 OC-helper out 时可能"顺手"上前者, 改了 Daemon/CMakeLists.txt 触发 H2 越界。

Codex 自觉防御性把 CMakeLists 显式列严禁, 这是个非常好的做法。

但 lite [`03-codex-orchestrate.md > 子任务包模板`](.ai/prompts/03-codex-orchestrate.md) 当前模板:

```markdown
- 本子任务涉及的 paths (核心): file1, file2
- 本子任务涉及的 paths (连带, 允许小改): file3
- 严禁动的 paths: 其余全部
```

"严禁动 paths: 其余全部" 是**通用兜底**, 没强约束 Codex 列**具体高风险 paths**。Codex 这次是自创防御, 不是模板 force 的。换个 LLM 或 fresh session 可能想不到列具体路径, 漏掉防御。

## 影响
- 不严重 (P3) — 这次 Codex 自觉做了
- **但**模板没 force, 下次可能漏:
  - OC-impl 顺手改了不在核心/连带但**邻近**的高风险路径 (如本例的 CMakeLists, 或 schema migration, 或公共 header, 或 build script)
  - H2 验证只看"是否在 paths 列表内", 不会主动 flag "改了模板没列但显然高风险"的文件
  - bug 修复偏离 minimal patch 精神

## 根因
[`03-codex-orchestrate.md > 子任务包模板`](.ai/prompts/03-codex-orchestrate.md) "上下文"段把"严禁动"当兜底, 不当强约束。Codex 自然倾向写"其余全部"省事, 不列具体高风险路径。

## 证据
- 本对话 2026-05-18 01:xx Codex 输出的 `.ai/scratch/oc-impl-package-daemon-singleton-1.md` 第 8 行:
  ```
  - 严禁动: PublicFunction/, MsgTransManager/, 其它 Dc*/Kit* 业务管家, Daemon/CMakeLists.txt
  ```
- 这是**好实践**, 但模板没 force, 是 Codex 自觉发挥; 换个 OC 模型可能想不到列 CMakeLists 这种"邻近但不在 paths 内"的高风险路径

## 提议修复

### 1. **`03-codex-orchestrate.md > 03a · 拆任务 > 子任务包模板`** 改写"上下文"段:

```markdown
## 上下文
- task brief: <path, 通常 .ai/tasks/<id>.md>
- pre-decisions 摘要: D1=..., D2=..., D3=...
- 本子任务涉及的 paths (核心): file1, file2
- 本子任务涉及的 paths (连带, 允许小改): file3
- **严禁动的高风险 paths** (Codex 必须列 ≥ 1 条具体路径, 不允许只写"其余全部"):
  - <具体路径 1> · 列在这里的理由: <一句话 e.g. "构建配置, 改它影响整个子项目编译">
  - <具体路径 2> · 理由: <e.g. "公共 header, 改它跨子项目 ABI 影响">
  - <具体路径 3> · 理由: <e.g. "schema migration, 改它影响 DB 状态">
  - 其余全部 (兜底)

**Codex 03a 写"严禁动高风险 paths"段时必须考虑**:
- 子任务包"必做"段提及的任何 keyword (build / config / schema / proto / migration) 对应的实际文件
- 上一轮 OC-helper / GitNexus 提到的"邻近但不在核心 paths 内"的文件
- 项目历史上踩过类似 scope 越界的文件 (查 .ai/logs/ + AGENTS.md > Known Sharp Edges)

**OC-impl 03b 读到本段时必须**:
- 解析"严禁动的高风险 paths"列表
- 实施前 `git diff --cached --stat` 自检时, 不仅核对在不在 paths 列表内, 还要核对**没动严禁动的高风险 paths 列表**
- 命中任一严禁动 → 立即回退 + 输出"撞墙: 触及严禁动 paths X"
```

### 2. **`03b-opencode-impl.md > Scope 强约束`** 段补严禁动核对:

```markdown
改动后、测试前, 跑:

```bash
# Scope 自检 (v0.2.0 双层验证)
cd <子项目根> && git diff --cached --stat
```

逐行核对:
1. 每个文件路径都在子任务包 paths 列表内 (核心 + 连带)
2. **没动子任务包"严禁动的高风险 paths"列表** (v0.2.0 新增)

任一未通过 → 立即停下回退 (unstage 或恢复), **不要**先跑测试再说。
```

### 3. **`oc-code-quality-rubric.md > H2`** 验证段补显式核对:

```markdown
- [ ] **H2**. paths 二组分: OC-impl 只动了"核心 paths" + 子任务包明确许可的"连带 paths"
  - 验证方法: `cd <子项目> && git diff --cached --stat`, 逐行核对
  - **额外核对** (v0.2.0): 没动子任务包"严禁动的高风险 paths" 列表中任一条; 触及任一 → H2 直接 fail
```

## SemVer 影响
**PATCH** (强化现有模板, 不破坏 v0.1 旧子任务包 · 旧子任务包"严禁动: 其余全部"仍合法, 只是不达 v0.2 best practice; H2 验证逻辑增量, 不退化)。

## 关联与对照
- 与 **F09** (rubric H2 多 git paths 验证) 关联: F09 修验证 cwd 范围, F15 修验证内容 (加"严禁动核对")
- 与 **F14** (03a 子任务包落档) 关联: F14 让子任务包跨 session 可见, F15 让子任务包内容更 force; 都是 03a 阶段 quality 强化

---

## v0.2.0-lite-rc1 实施记录 (2026-05-18)

- **release**: v0.2.0-lite-rc1
- **触发来源**: smart-uite epic (Daemon 单例 bug, commit 9afc2f7) 实战 dogfood 反馈 — lite v0.1 首次真实大型项目接入
- **实施摘要**: 见 `CHANGELOG.md > [v0.2.0-lite-rc1]` 段, 本 finding (F15) 落入对应分组 (group A/B/C/D/E/F/G), 详见 CHANGELOG `### Why these changes` 段
- **关联 commit**: 见 `git log --oneline v0.1.0-lite-rc1..v0.2.0-lite-rc1` (release 提交 hash 由 Step 6 tag 后填入)
- **archive 路径**: `.ai/logs/archived/v0.2-released/lite-v0.1-finding-15-subtask-package-strict-forbidden-paths.md`
