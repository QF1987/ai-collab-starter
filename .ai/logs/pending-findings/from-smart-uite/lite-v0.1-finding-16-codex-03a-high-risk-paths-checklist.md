---
finding-id: lite-v0.1-finding-16-codex-03a-high-risk-paths-checklist
severity: P2
category: prompt + checklist
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/prompts/03-codex-orchestrate.md (03a 子任务包 "严禁动" 段加高风险类别 checklist)
  - .ai/prompts/02-codex-plan.md (§7 OC delegation candidates 段加"高风险 paths 预审"提醒)
status: pending
related: [15, 09]
---

# Finding 16: Codex 03a 列"严禁动 paths"应有高风险类别 checklist, 防漏列 config / migration / schema 类

## 现象
smart-uite Daemon bug 03b OC-impl 触发了**第 1 轮 verify fail**, 因为 OC-impl 在跑测试时撞墙顺手改了 `Daemon/config/Daemon.ini` (12 add / 3 del), 不在子任务包 paths 列表, 触发 H1 D3 + H2 paths 越界。

回看 03a 子任务包 "严禁动 paths" 段 (`.ai/scratch/oc-impl-package-daemon-singleton-1.md` line 8):

```
- 严禁动: PublicFunction/, MsgTransManager/, 其它 Dc*/Kit* 业务管家, Daemon/CMakeLists.txt
```

Codex 自觉列了 4 类 (兄弟子项目 / 业务管家 / CMakeLists), **但漏了 config/ 这一高风险类**。Daemon 子项目下有 `Daemon/config/Daemon.ini`, 它是运行时配置 (ProcessList / WaitTime / 各业务管家路径), 跟 daemon-singleton bug 无关但跟"测试时跑 Daemon"强相关 (Daemon 启动会读 ini, OC-impl 跑测试时撞墙顺手改了 ini 让 Daemon "跑得起来")。

Finding 15 已经修了"Codex 必须列 ≥ 1 条具体路径", 但**没指导 Codex 想到哪些类别需要列**。F16 是 F15 的具体化: 给 Codex 一份"高风险类别 checklist", 强制至少**逐项考虑过**。

## 影响
- **真实 03b retry**: 本次 smart-uite Daemon bug 第 1 轮 verify fail 就因 config/ 没列严禁动, 浪费 1 轮 OC-impl + 1 轮 Codex 03c 时间
- **跨项目通用**: 几乎所有项目都有 config/ migration/ schema/ proto/ 类目录, 都是"邻近核心代码但改了就破坏 minimal patch"的高风险类
- **Finding 15 修了形式 (必须列), F16 修内容 (列哪些)**

## 根因
- [`03-codex-orchestrate.md > 03a · 拆任务 > 子任务包模板`](.ai/prompts/03-codex-orchestrate.md) "上下文 > 严禁动" 段 (F15 修后强约束 ≥ 1 条) 没附"高风险类别 checklist", Codex 自己想到啥列啥
- 02-codex-plan.md §7 OC delegation candidates 段也没要求 02 阶段就预审"哪些路径属于高风险, 03a 时务必列严禁动"

## 证据
- 本对话 2026-05-18 01:xx OC-impl 03b 跑完, `git diff Daemon/config/Daemon.ini` 显示 12 add / 3 del 完全无关本 bug
- 子任务包"严禁动"段没列 `config/`, OC-impl 撞墙时没有 ground truth 阻止它顺手改

## 提议修复

### 1. **`03-codex-orchestrate.md > 03a 子任务包模板 > 上下文 > 严禁动 paths` 段** 加高风险类别 checklist:

```markdown
- **严禁动的高风险 paths** (Codex 必须列 ≥ 1 条具体路径 + 一句话理由 · F15):
  Codex 03a 写本段时, 必须**逐类**核对下列 6 大高风险类别, 列出本子任务下 ≥ 1 条具体路径 + 理由 (若该类不适用, 标 N/A):

  | 类别 | 典型路径模式 | 列严禁动的理由 |
  |------|------------|----------------|
  | **构建配置** | CMakeLists.txt / build.gradle / package.json / Cargo.toml / Makefile / *.vcxproj | 改它影响整个子项目编译 / 引入新依赖 / 改 ABI |
  | **运行时配置** | config/*.ini / config/*.yaml / config/*.json / .env / application*.properties | OC-impl 跑测试时撞配置缺失常顺手改 — 实战重灾区 (F16 触发本类) |
  | **schema / migration** | migration/*.sql / schema/*.sql / *.proto / *.thrift / db/migrate/* | 改它影响 DB 状态 / 跨服务协议契约 |
  | **公共 header / ABI** | include/* / public/* / api/* / *.h (公共 export) | 改它跨子项目 ABI 影响 |
  | **CI / 部署脚本** | .github/workflows/* / .gitlab-ci.yml / scripts/deploy.sh / Dockerfile | 改它影响发布流程 / 跑测试时容易撞 |
  | **第三方依赖** | vendor/ / 3rdLibraries/ / third_party/ / external/ / node_modules/ | 跟 F11 OC-helper 第三方过滤呼应; OC-impl 顺手 patch 第三方更新 |
  | (其它) | 项目特定 | <如有 e.g. legacy_module / generated_code / fixtures> |

  - <具体路径 1> · 类别: <构建配置 / 运行时配置 / ...> · 理由: <一句话>
  - <具体路径 2> · 类别: ... · 理由: ...
  - 其余全部 (兜底)
```

### 2. **`02-codex-plan.md > §7 OC delegation candidates`** 段加预审项:

```markdown
### OC-impl 子任务包 (03a 阶段展开)
... (现状: 列子任务包名 + 一句话)

**Codex 02 输出 brief 时同步思考 (为 03a 高风险 paths 列准备)**:
- 本 task 涉及的子项目, 有哪些 `构建配置 / 运行时配置 / schema / 公共 header / CI / 第三方依赖` 类目录?
- 这些类目录里哪些文件**可能**在 OC-impl 实施期撞墙顺手改?
- 把可能撞墙的路径在 brief 末尾 "OC delegation candidates" 段标 "03a 严禁动候选: <路径>", 让 03a 阶段 Codex 不漏列

```

### 3. **`oc-code-quality-rubric.md > 维度低分常见模式速查 · D5 fail 信号` 段** 加新条目:

```markdown
### D5 fail 信号 (v0.2.0 加)
- 单文件 diff 行数远超合理估计
- 动了 brief 没列的 import / package 重排
- "顺手"重命名了无关变量
- **改了 config/*.ini / .env / config.yaml 等运行时配置 (F16): OC-impl 跑测试撞墙顺手改, 是 lite v0.1 实战重灾区**
- **改了 *.proto / migration/*.sql / 公共 header (F16): 架构敏感, 应升 Codex 02 重切**
```

## SemVer 影响
**PATCH** (现有 prompt 加 checklist 段, 旧 brief 没逐类核对仍合法, 只是不达 v0.2 best practice; 现有 rubric D5 描述增量, 不退化)。

## 关联与对照
- **F15** 修"必须列 ≥ 1 条具体路径"形式; **F16** 修"列哪些类别"内容
- **F09** 修"H2 验证 cwd 范围 (多 git)"; **F15/F16** 修"H2 验证内容 (严禁动列表)" — 三者一起把 paths 验证补全
- **F11** OC-helper 第三方过滤 + **F16** 严禁动列第三方依赖类 — 双层防 OC 漫游第三方
- **F14** 03a 落档 + **F15/F16** 落档内容更 force — 03a quality 强化矩阵
