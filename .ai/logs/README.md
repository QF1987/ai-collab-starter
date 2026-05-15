# Starter Findings Inbox

> **作用**:跨项目 finding 汇聚的 SoT(single source of truth)。任何 derived 项目在 dogfood
> 过程中 discover 的 starter 改进 finding,**必须同步一份到这里**,才能被未来 starter 升级看到。
>
> **为什么需要**:v3.0 之前的架构里,finding 散在各 derived 项目的 `.ai/logs/` 下,
> ai-collab-starter 自己看不到。新 session 的 Claude 无法知道有多少待实施的 finding。
> v4.0(本 inbox)解决这个跨 session 信息汇聚问题。

## 目录结构

```
.ai/logs/
├── pending-findings/          # 待实施的 finding(下次 starter 升级时考虑)
│   ├── from-<project-name>/   # 按来源项目分桶
│   │   └── starter-vN-finding-NN-*.md
│   └── ...
├── archived/                  # 已实施 finding 归档(audit trail)
│   ├── v2.0-released/         # v2.0 时实施的
│   ├── v3.0-released/         # v3.0 时实施的
│   └── vN.0-released/         # 未来 release 时归档
└── README.md                  # 本文件
```

## 状态分类

| 子目录 | 含义 |
|--------|------|
| `pending-findings/from-<project>/` | 该项目 discover 的 finding,尚未在任何 starter release 实施 |
| `archived/vN.0-released/` | 已在 vN.0 实施(对应 CHANGELOG vN.0 段)。归档用于 audit trail |

**rejected / deferred** 类 finding **保持** 在 `pending-findings/`,在文件内 frontmatter 标
`status: deferred` + 原因。这样下次 release 仍会被回顾(可能条件变化重新考虑)。

## 双写约定(任何项目 discover finding 时必做)

1. 在项目本地 `.ai/logs/starter-vN-finding-NN-*.md` 写 finding(本地 audit trail)
2. **同时**复制一份到 `ai-collab-starter/.ai/logs/pending-findings/from-<project-name>/`

可手工 cp,或跑 `ai-collab-starter/scripts/sync-finding.sh <local-finding-path>`(自动找
project-name 并 copy)。

## 命名约定

文件名:`starter-vN-finding-NN-<short-slug>.md`(沿用 v2.0 起的约定)

其中 `vN` 是 starter 当前 minor 版本(v2/v3/v4/...),`NN` 在所有项目跨项目**全局递增**
(NN 在 inbox 内必须唯一,即使来自不同项目)。**写新 finding 前查 inbox 当前最大 NN**:

```bash
ls ai-collab-starter/.ai/logs/pending-findings/from-*/ \
   ai-collab-starter/.ai/logs/archived/*/ \
   2>/dev/null | grep -oE 'finding-[0-9]+' | sort -V | tail -1
```

## 由 starter 升级 session 消费

下次 starter 升级 session(`starter-upgrade-protocol.md`)时:

1. `ls pending-findings/from-*/` 看新增 finding 总量
2. 按 P0/P1/P2/P3 分桶决定 release 类型(MAJOR / MINOR / PATCH)
3. 实施时挪文件 `pending-findings/ → archived/vN.0-released/`
4. CHANGELOG 写明哪些 finding 进 release

## 状态查询

任意项目 / starter 自己跑:

```bash
bash ai-collab-starter/scripts/starter-status.sh
```

输出当前 inbox 状态 + 触发 release 阈值(详见脚本)。
