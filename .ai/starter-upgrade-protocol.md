# Starter Upgrade Protocol

> **作用**:跨 session 的 starter 升级仪式 SoT。任何 Claude session 想升级 starter,**按本文档 7 步走**——
> 无论这个 Claude 之前是否见过 starter 历史。
>
> **为什么需要**:v3.0 之前升级靠 Claude 当下记忆 + Human 提示词。Claude 跨 session 没记忆,
> Human 也可能忘细节。本协议把升级流程**完全外部化**到文件,让 starter 自演化不依赖具体 session 上下文。

## 触发条件(任一即可启动)

| 触发 | 条件 | 紧迫度 |
|------|------|-------|
| **阈值** | inbox 累计 pending ≥ 5 finding(跑 `scripts/starter-status.sh` 查) | 中(建议本周) |
| **严重度** | inbox 任一 P0/P1 finding | 高(建议立即) |
| **时间** | 距上次 release ≥ 30 天 且 inbox ≥ 1 finding | 中(月度回顾) |
| **形态发现** | 跑通新形态 task(如 ops-only / 新语言 / 新框架),starter 缺该形态支持 | 低(可累积) |
| **Human 显式** | Human 说"启动 starter 升级" | 立即 |

非紧迫触发可累积。**任意一个触发到来,Claude 应主动提醒 Human**(参考 AGENTS.md > Claude 主动提醒升级段)。

## 7-step 升级仪式

### Step 1 · 状态盘点(5-10 min)

```bash
cd <path-to-ai-collab-starter>
bash scripts/starter-status.sh
ls .ai/logs/pending-findings/from-*/   # 看分桶
```

记下:
- 当前 starter VERSION
- inbox 累计 finding 数 + 按 P0/P1/P2/P3 分布
- 距上次 release 时间(`git log --oneline -1 -- CHANGELOG.md`)

### Step 2 · 读完所有 pending findings(15-30 min)

```bash
for f in .ai/logs/pending-findings/from-*/*.md; do
  echo "===== $f ====="
  head -30 "$f"   # 看 frontmatter + 现象 + 影响
done
```

读完每条 finding,记下:
- severity(P0/P1/P2/P3)
- 提议的 fix 涉及哪个 prompt / 文件
- 是否与其他 finding 主题相关(可合并升级)

### Step 3 · 分桶 + 决定版本号(10-15 min)

把每条 finding 归入 3 桶:

| 桶 | 含义 | 影响 release 类型 |
|---|------|----------------|
| **必修** | 进本次 release | 决定版本号 |
| **可选(deferred)** | 留 inbox,等下次 release | 不影响 |
| **拒收** | 评估后觉得不需要;在原文件加 frontmatter `status: rejected` + reason | 不影响 |

**SemVer 决策树**:
- 任一**必修**是 P0/P1 或 涉及删除/重命名 prompt → **MAJOR**
- 任一**必修**是 P2 或 涉及新增能力 → **MINOR**
- 全部**必修**是 P3 wording/typo/docs → **PATCH**

口述给 Human 确认分桶 + 版本号。**用 AskUserQuestion 一次性问完**,不要碎步交互。

### Step 4 · 实施 patches(30-90 min,看必修条数)

按必修桶逐条实施。每条 finding 文件**末尾**记录:
- 实施方式(改了哪些文件,加 / 删 / 改的具体内容)
- 关联 commit hash(实施后 commit,然后回填 hash)

实施纪律:
- **同主题 finding 一起改**(避免来回 grep 文件 N 次)
- **保留原文 + 加 v(N).0 标记**(像 `## 收尾纪律(v3.0 / Finding #21 强约束)`),不删旧版
- **改 prompt 时不破坏 v1.0 contract**(MAJOR 例外,但要在 CHANGELOG 显式说明)

### Step 5 · 移动归档 + 写 CHANGELOG(15 min)

实施完每条必修后:

```bash
git mv .ai/logs/pending-findings/from-<project>/<finding-file>.md \
       .ai/logs/archived/v(N).0-released/
```

写 CHANGELOG.md 新段:

```markdown
## [v(N).0.0] — YYYY-MM-DD

### TL;DR
<一句话来源 + 实施数量 + breaking change 摘要>

### 实战数据
<触发本次 release 的 dogfood 简述>

### Added / Changed / Removed
<按 finding 编号列实施内容,引用 finding 文件路径>

### Why these changes
<每条 finding 触发的实战 case 简述>

### Breaking changes
<若 MAJOR,列具体 contract 变更>

### 升级指南
<derived 项目如何 sync 到本版本>
```

参考 v2.0/v3.0 段的格式。

### Step 6 · 更新 VERSION + commit + tag + push(5-10 min)

```bash
echo "v(N).0.0" > VERSION
git add VERSION CHANGELOG.md .ai/ scripts/   # 含归档移动
git commit -m "release(v(N).0.0): <X> findings from <来源项目>

<逐条 finding 简述>

无 breaking change(若 MINOR)
或: Breaking change: <具体>(若 MAJOR)"

git tag -a v(N).0.0 -m "Release v(N).0.0 - <简述>"
git push origin main --tags
```

**rc 模式**:若本次升级**未经实战 dogfood**(纯理论 derived),tag 用 `v(N).0.0-rc1`,
CHANGELOG 段加 `> ⚠️ 本版本待实战 dogfood 验证后翻 stable`。

### Step 7 · 同步到 derived 项目(可选,Human 决定)

对每个 derived 项目:

```bash
# 在 derived 项目根:
rsync -av --exclude='.git' /path/to/ai-collab-starter/.ai/prompts/ .ai/prompts/
rsync -av /path/to/ai-collab-starter/.ai/intake-templates.md .ai/
rsync -av /path/to/ai-collab-starter/.ai/workflow.md .ai/
# (state.md / decisions.md / context.md 项目特定,按需 surgical merge)

echo "v(N).0.0  · synced YYYY-MM-DD" > .ai/STARTER_VERSION

# 在 derived 项目 .ai/progress.md 加一行印迹:
echo "- $(date +%Y-%m-%d) · starter v(N).0.0 同步,详见 ai-collab-starter CHANGELOG" >> .ai/progress.md
```

**rc 版本默认不强推**:`STARTER_VERSION` 仅在 stable 版本 sync,rc 留作 starter 自身实验。

---

## 协议元数据

- 创建版本: v4.0.0-rc1
- 上次修订: 2026-05-15
- 维护责任: 本协议本身也接受 finding 反馈(在 inbox 标 `target: starter-upgrade-protocol.md`)

如果跑这套仪式时遇到具体步骤不顺手 / 漏考虑,**记一条 finding 到 inbox**(参考"何时落 finding"
约定,见 workflow.md)。下次升级会自然回顾本协议本身。
