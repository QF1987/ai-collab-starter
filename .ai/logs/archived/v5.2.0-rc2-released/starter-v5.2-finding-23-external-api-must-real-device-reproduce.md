---
finding-id: starter-v5.2-finding-23-external-api-must-real-device-reproduce
severity: P1
category: prompt (02-claude-plan 强约束)
source-project: DeviceOps
discovered: 2026-05-24
target:
  - .ai/prompts/02-claude-plan.md(强约束段加 Finding #23)
status: pending
related: [22]
---

# Finding 23: ADR 锁定外部 API 行为契约前,必须真机/桌面跑最小复现验证 getter

## 现象

DeviceOps M3-Beta S2 中,Claude 02-plan 在 ADR-20260523-02 amendment v1 锁定 libtorrent
`torrent_handle::set_max_uploads(0)` 作为「停 outgoing upload」实现,**仅基于 libtorrent header doc**:
> `set_max_uploads()` ... If you set this to -1, there will be no limit. This defaults to infinite.

doc 明示 `-1=unlimited`,**未定义 `0` 的语义**。Plan 推断「0 = 最严格限制 = 实质停 upload」。

Impl 实施后 commit `38b84dd` → 真机 `192.168.31.239:41337` 上 `p2p_download_manager_test` 断言
`max_uploads()==0` **fail**:实测 getter 返回 `16777215`(libtorrent 内部 unlimited 哨兵),证明 setter 把
`0` 也规范化为 unlimited。

Escalate → Claude amendment v2 改锁 `set_max_uploads(1) + set_upload_limit(5120)` 组合,Impl 二次提交
`1d5d1f2` 才闭合。一次 ADR amendment 二次迭代,消耗约 30k token。

## 影响

- ADR amendment v1 → v2 二次迭代成本(本次 ~30k token);若 P1 finding 触发了 prod release rollback,代价更大
- 信任损失:下游 Agent(Impl)对 ADR 锁定值的可靠性产生疑虑,可能反向引发「不信任 brief,自己探针验证」反模式
- 现有 Finding #22 覆盖了「新增内部符号 grep 同包预检」(静态可见),但外部第三方 API 行为契约属于**动态可见**风险,#22 未触及

## 根因

starter v5.1.0 `02-claude-plan.md` 强约束 #22「锁定新增符号名前必须 grep 同包预检」处理的是
「Claude ADR 静态承诺 vs Impl 实施期撞墙」陷阱的**静态维度**:
- 内部新增符号冲突 → grep 可查 → 已有强约束
- 外部 API 行为偏离 doc → grep 看不到,必须运行时验证 → **强约束空白**

典型空白场景:
- libtorrent / Boost / 嵌入式 SDK 的 setter 规范化逻辑(如 `if (v <= 0) v = SENTINEL`)
- OS API 在不同 ROM / kernel 版本上的行为差异(如 Android NetworkCapabilities VoLTE 桥接)
- 第三方 SDK 文档未明确定义的边界值(如 `-1` 定义但 `0` 未定义)
- Native FFI / JNI 类型转换中的 implicit casting 副作用

## 证据

- ADR-20260523-02 amendment v1(2026-05-24)锁 `set_max_uploads(0/-1)`(`DeviceOps/.ai/decisions.md` L590 区)
- Impl commit `38b84dd`(实施 v1)+ Impl note in review.md RV-20260524-01:
  > 临时探针把 stop 值改成 1 时 `handle.max_uploads()` 会变成 1;恢复 amendment 指定 0 后 getter 保持 16777215(unlimited 编码)
- ADR-20260523-02 amendment v2(同日)改锁 `(1, 5120)` 组合
- Impl 二次 commit `1d5d1f2` 真机断言 PASS
- 完整复盘见 `DeviceOps/.ai/logs/M3-B-starter-dogfood-2026-05-24.md`

## 提议修复

`.ai/prompts/02-claude-plan.md` 强约束段(在 Finding #22「锁定新增符号名前 grep 同包预检」之后)追加:

```markdown
##### 锁定外部 API 行为契约前必须最小复现验证(v5.2.x · Finding #23 强约束)

在 ADR 中**锁定第三方 API 的具体值或行为契约**时(典型场景:libtorrent flag / OS SDK getter
行为 / SDK enum 边界值 / FFI 类型转换 / Native 库 setter 规范化逻辑),Claude **必须**
在最终化 ADR 前完成**两层验证**:

1. **文档证据**(已有约束):grep 上游源 / 头文件 / 官方 doc 取语义证据
2. **行为证据**(本约束新增):在目标环境(真机 / 桌面 / 对应 SDK 版本)跑最小复现脚本,
   验证 getter 返回值符合预期

**禁止**:仅凭文档推断**未明确定义**的值(典型反例:doc 说「`-1` = unlimited」,推断「`0` 也是
最严格限制」—— libtorrent 实际把 `0` 也规范化为 unlimited)。

**何时本约束触发**(避免误用):
- 仅当 ADR 锁定的是「外部不可控行为」(第三方 API / OS API / 硬件接口)时强制
- 纯内部模块 / web API / DB schema 等可控领域不强制(由现有 #22 / L1-L5 分级覆盖)

**最小复现脚本要求**:
- 落档 `.ai/logs/<adr-id>-api-probe.md`,含调用代码 + 真机实测 getter 返回值 + 环境信息
- ADR Decision 段引用此 probe log 路径,作为锁值证据

**反例(留底)**:DeviceOps M3-Beta ADR-20260523-02 amendment v1 锁 `set_max_uploads(0)` 仅
基于 doc,实施后真机 getter 返回 16777215(unlimited)→ amendment v2 二次迭代,~30k token 浪费。
```

## 优先级建议

- 本 finding 推荐 starter v5.2.x release 时合入(P1 = 建议立即,见 `starter-upgrade-protocol.md`)
- lite v0.7.x 同步加入(Lead prompt 写 plan 时同样适用)
