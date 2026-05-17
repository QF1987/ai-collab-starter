---
finding-id: lite-v0.1-finding-11-oc-helper-3rd-party-filter
severity: P3
category: prompt
source-project: smart-uite
discovered: 2026-05-18
target:
  - .ai/prompts/oc-helper.md (执行规则 grep 段 + req 文件格式 默认字段)
status: pending
related: []
---

# Finding 11: OC-helper 默认应过滤第三方代码命中 (vendor / boost / node_modules 等)

## 现象
smart-uite Daemon 单例 bug L2 摸排时, OC-helper grep `CreateMutex` / `OpenMutex` / `ReleaseMutex` / `WaitForSingleObject` 等 Win32 keyword 在 `Daemon/` + `PublicFunction/` + `MsgTransManager/` 范围内, 命中里**绝大多数来自 boost interprocess / boost winapi 头文件** (third party 第三方代码), 跟 bug 无关。

OC-helper **自主行为**: 把命中分两列, 列出 "boost 头文件" 命中作为单独类别, 业务代码命中单独列, 极大降低 Codex 02 阅读 noise。

这是好行为, **但 oc-helper.md 契约里没写这条约束** — OC 自主发现的, 不是 prompt force 的。下次换个 OC 模型 (e.g. 不同国产模型 / 不同版本) 可能就不这么聪明了。

## 影响
- 不严重 (P3) — 当前 OC 跑通靠默契
- 但 lite 设计哲学 "无协议, 文件即真相" 要求**行为可预测**, 不能靠 OC 自主判断关键 quality 项
- 若下次 OC 不过滤, Codex 02 收到 200+ 条 boost 命中混在业务命中里, 解读极度低效, 可能漏过真问题

## 根因
[`oc-helper.md`](/Users/qf/Alcedo/code/ai-collab-starter-lite/.ai/prompts/oc-helper.md) `## 执行规则 > grep 任务` 段没说默认过滤路径; req 文件格式模板也没有 `exclude_paths` 字段。

## 证据
- 本对话 OC-helper 输出 `.ai/scratch/oc-helper/out-daemon-singleton-1.md` 命中摘要表格主动加了 "命中数(去boost)" 列, 注释 "仅 boost 头文件" 字样, 并在 notes 段第 1 条写 "所有 boost/ 目录下的命中均为第三方头文件，与本 bug 无关，已过滤"
- 这是 OC 自主行为, oc-helper.md 没要求

## 提议修复

### 1. **`oc-helper.md > 执行规则 > grep 任务` 段** 加默认过滤清单:

```markdown
### grep 任务

```bash
# 按 req.action 跑 grep, 严格遵守 max_matches
grep -rn -C <context_lines> "<pattern>" <path> \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  --exclude-dir=vendor \
  --exclude-dir=3rdLibraries \
  --exclude-dir=third_party \
  --exclude-dir=external \
  --exclude-dir=boost \
  --exclude-dir=Boost \
  --exclude-dir=.venv \
  --exclude-dir=venv \
  --exclude-dir=__pycache__ \
  --exclude-dir=build \
  --exclude-dir=Release \
  --exclude-dir=Debug \
  --exclude-dir=dist \
  --exclude-dir=target \
  | head -<max_matches>
```

**默认过滤理由**:
- `.git` — 仓 metadata, 不是源码
- `node_modules` / `vendor` / `3rdLibraries` / `third_party` / `external` — 第三方依赖, 与业务无关
- `boost` / `Boost` — 大型 C++ 第三方头文件, 命中噪音特别大 (实战来自 smart-uite Finding 11)
- `.venv` / `venv` / `__pycache__` — Python 第三方依赖与缓存
- `build` / `Release` / `Debug` / `dist` / `target` — 构建产物, 不是源码

**例外**: 若 req `intent` 段明确说 "包括第三方依赖" / "包括 vendor 目录" (e.g. 排查依赖版本漂移 bug), req `action` 加 `include_third_party: true`, OC-helper 移除上述 --exclude-dir。
```

### 2. **`oc-helper.md > req 文件格式` 模板加 exclude_paths 可选字段**:

```markdown
## action
- type: grep | scan | summarize
- pattern / path / file: ...
- context_lines: 3
- max_matches: 100
- include_third_party: false  # 默认 false, OC-helper 自动 --exclude-dir 第三方目录
- additional_exclude_dirs: []  # 项目特定额外过滤目录, e.g. ["legacy_module"]
```

### 3. **`oc-helper.md > out 文件格式` notes 段加默认条目要求**:

```markdown
## notes
(自由文本: 异常 / 建议 / 你发现的可疑模式; 简短即可, ≤ 5 行)

**若 include_third_party=false 且命中过滤掉了 ≥ 10 条第三方命中, notes 必须显式标一行**:
"已默认过滤 N 条第三方命中 (路径: boost / vendor / 3rdLibraries 等), 业务代码命中数: M。若需查看第三方命中, req 加 include_third_party: true。"
```

## SemVer 影响
**PATCH** (现有 oc-helper.md 加默认过滤 + 可选字段, 现有 req 不写新字段仍兼容)。
