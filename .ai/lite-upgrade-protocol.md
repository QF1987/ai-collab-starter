# lite Upgrade Protocol (v0.1.0)

> **作用**: 跨 session 的 lite 自演化升级仪式 SoT。Human 主导,Lead 辅助。
>
> **与 main 的区别**: main 升级仪式是 Claude 主导(starter-upgrade-protocol.md);
> lite 因无 Claude,**升级由 Human 亲自跑**——Lead 可以帮 grep / draft CHANGELOG,
> 但版本号决策、findings 分桶、tag/push 是 Human 的活。

## 触发条件 (任一即可启动)

| 触发 | 条件 | 紧迫度 |
|------|------|-------|
| **阈值** | inbox 累计 pending ≥ 5 finding(`ls .ai/logs/pending-findings/`) | 中(建议本周) |
| **严重度** | inbox 任一 P0/P1 finding | 高(建议立即) |
| **时间** | 距上次 release ≥ 30 天 且 inbox ≥ 1 finding | 中(月度回顾) |
| **形态发现** | 跑通新形态 task,lite 缺该形态支持 | 低(可累积) |
| **main → lite sync** | main 发了新 MINOR/MAJOR 且含通用改进 | 中(评估后引入) |
| **Human 显式** | Human 说"启动 lite 升级" | 立即 |

非紧迫触发可累积。

## 7-step 升级仪式

### Step 1 · 状态盘点 (5-10 min · Human + Lead 协助)

```bash
cd <path-to-ai-collab-starter-lite>
cat VERSION
ls .ai/logs/pending-findings/from-*/   # 看分桶, 若有
git log --oneline -1 -- CHANGELOG.md   # 上次 release 时间
```

记下:
- 当前 lite VERSION
- inbox 累计 finding 数 + 按 P0/P1/P2/P3 分布(若 inbox 不存在则跳过)
- 距上次 release 时间

### Step 2 · 读完所有 pending findings (15-30 min · Human)

```bash
for f in .ai/logs/pending-findings/from-*/*.md; do
  echo "===== $f ====="
  head -30 "$f"
done
```

读完每条 finding,Human 记下:
- severity(P0/P1/P2/P3)
- 提议的 fix 涉及哪个 prompt / 文件
- 是否与其他 finding 主题相关(可合并升级)
- 是不是 Claude-specific(若是,lite 不引入)

### Step 3 · 分桶 + 决定版本号 (10-15 min · Human 决策)

把每条 finding 归入 3 桶:

| 桶 | 含义 | 影响 release 类型 |
|---|------|----------------|
| **必修** | 进本次 release | 决定版本号 |
| **可选 (deferred)** | 留 inbox,等下次 release | 不影响 |
| **拒收** | 评估后觉得不需要 / Claude-specific;在原文件加 frontmatter `status: rejected` + reason | 不影响 |

**lite SemVer 决策树**:

- 任一**必修**是 P0/P1 或 涉及删除/重命名 prompt → **MAJOR**(v0.X.Y → v0.X+1.0 或 v1.0.0)
- 任一**必修**是 P2 或 涉及新增能力 → **MINOR**
- 全部**必修**是 P3 wording/typo/docs → **PATCH**

> **lite v0.X 期间**: MAJOR 突变保留在 v0.X+1.0 形式(不冲 v1.0.0),给设计迭代留余地。
> 等 lite 跑过 ≥ 3 个真实 epic 验证稳定后再翻 v1.0.0 stable。

### Step 4 · 实施 patches (30-90 min · Human 主导, Lead 拆任务 + Impl 写)

按必修桶逐条实施。**遵循 lite 03 三段式**:

1. Human 把每条 finding 写成 brief
2. Lead 02 / 03a 拆任务
3. Impl 03b 写代码
4. Lead 03c 验收(走 rubric)
5. Reviewer 04 审

每条 finding 文件**末尾**记录:
- 实施方式(改了哪些文件,具体内容摘要)
- 关联 commit hash(实施后 commit,然后回填 hash)

实施纪律:
- **同主题 finding 一起改**
- **保留原文 + 加 v(N).0 标记**,不删旧版
- **改 prompt 时不破坏 v0.1.0 contract**(MAJOR 例外,CHANGELOG 显式说明)

### Step 5 · 移动归档 + 写 CHANGELOG (15 min · Lead 起草, Human 终审)

实施完每条必修后:

```bash
mkdir -p .ai/logs/archived/v0.X-released/
git mv .ai/logs/pending-findings/from-<project>/<finding-file>.md \
       .ai/logs/archived/v0.X-released/
```

写 CHANGELOG.md 新段(Lead 起草,Human 改后定稿):

```markdown
## [v0.X.Y] — YYYY-MM-DD

### TL;DR
<一句话来源 + 实施数量 + breaking change 摘要>

### 实战数据
<触发本次 release 的 epic 简述>

### Added / Changed / Removed
<按 finding 编号列实施内容, 引用 finding 文件路径>

### Why these changes
<每条 finding 触发的实战 case 简述>

### Breaking changes
<若 MAJOR, 列具体 contract 变更>

### 升级指南
<derived 项目如何 sync 到本版本>

### lite → main sync 候选
<本次实施的通用 finding 列表, sync 到 main inbox>
```

### Step 6 · 更新 VERSION + commit + tag + push (5-10 min · Human)

```bash
echo "v0.X.Y-lite" > VERSION
git add VERSION CHANGELOG.md .ai/ scripts/
git commit -m "release(v0.X.Y-lite): <X> findings from <来源项目>

<逐条 finding 简述>

无 breaking change(若 MINOR)
或: Breaking change: <具体>(若 MAJOR)"

git tag -a v0.X.Y-lite -m "Release v0.X.Y-lite - <简述>"
git push origin lite --tags
```

**rc 模式**: 若本次升级**未经实战 dogfood**(纯理论),tag 用 `v0.X.Y-lite-rc1`,
CHANGELOG 段加 `> ⚠️ 本版本待实战 dogfood 验证后翻 stable`。

### Step 7 · 同步到 derived 项目(可选, Human 决定)

对每个 derived 项目:

```bash
# 在 derived 项目根:
rsync -av --exclude='.git' /path/to/ai-collab-starter-lite/.ai/prompts/ .ai/prompts/
rsync -av /path/to/ai-collab-starter-lite/.ai/intake-templates.md .ai/
rsync -av /path/to/ai-collab-starter-lite/.ai/workflow.md .ai/
rsync -av /path/to/ai-collab-starter-lite/.ai/oc-code-quality-rubric.md .ai/
# state.md / decisions.md / context.md 项目特定, 按需 surgical merge

echo "v0.X.Y-lite  · synced YYYY-MM-DD" > .ai/STARTER_VERSION

echo "- $(date +%Y-%m-%d) · lite v0.X.Y-lite 同步, 详见 ai-collab-starter-lite CHANGELOG" >> .ai/progress.md
```

**rc 版本默认不强推**: `STARTER_VERSION` 仅在 stable 版本 sync。

### Step 8 · lite → main 双向 sync(可选)

详见 `.ai/lite-v0.1.0-design.md > §8`。

**lite → main**:
- 本次实施的通用 finding(非 Claude-specific 项)cp 到 main inbox 的 `from-lite-<project>/` 子目录
- prefix `from-lite-` 让 main 升级 session 能识别来源
- main 下次升级 session 时扫到

**main → lite**:
- main MINOR/MAJOR release 后, lite owner 评估通用改进
- 通用改进引入 lite 升级仪式
- Claude-specific(如 `claude-review-required` frontmatter)lite 跳过

---

## 协议元数据

- 创建版本: v0.1.0-lite
- 上次修订: 2026-05-16
- 维护责任: 本协议本身也接受 finding 反馈(在 inbox 标 `target: lite-upgrade-protocol.md`)

如果跑这套仪式时遇到具体步骤不顺手 / 漏考虑,**记一条 finding 到 inbox**。下次升级会自然回顾本协议本身。
