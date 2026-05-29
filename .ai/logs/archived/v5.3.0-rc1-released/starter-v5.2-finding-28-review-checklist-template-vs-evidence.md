---
finding-id: starter-v5.2-finding-28-review-checklist-template-vs-evidence
severity: P2
category: prompt(04-review 检查清单)
source-project: DeviceOps
discovered: 2026-05-26
target:
  - .ai/prompts/04-review.md(检查清单加「设计完整 vs 实测完整」区分项)
  - .ai/prompts/05-claude-review.md(若存在;Claude 复审同步)
status: pending
related: [26]
---

# Finding 28: Scout 04-review 检查清单缺「设计完整 vs 实测完整」区分项

## 现象

DeviceOps M3-Beta S4(epic 终点切片 · 3 台真机 E2E)实施过程中:
- **Impl 产出 6 个新文件**:`m3-beta-e2e.sh`(631 行)+ `simulate-network-switch.sh`(111 行)+ `README.md` + 3 个 scenario log 模板
- **3 个 scenario log 全是 `{{VAR}}` 占位符**(`{{RUN_ID}} / {{DATETIME}} / {{LOGCAT_TORRENT_URL_HITS}}` 等),**真机 E2E 实际没跑过**
- **Scout 04-review 走完三步法,verdict 是 "PASS · ESCALATE"**:7 AC 结构覆盖 ✅、零改动纪律 ✅、3 minor obs(非 blocking)
- Scout 把这个状态 escalate 给 Claude 终审,期望 Claude 判 epic CLOSED
- Claude 复审 spot-check 发现 **scenario log 全占位符** → 判 **NEEDS-EXECUTION**(不是 PASS,也不是 REJECT),拒绝判 epic CLOSED

也就是说:Scout 把「**设计完整**」(脚本 + 模板 + README 齐备 + 结构覆盖 AC)误判为「**实测完整**」(真机跑通 + 证据落档 + verdict=PASS),让模板占位符状态通过 review。

## 影响

- **epic-closeout 判定可信度损失**:Scout escalate PASS 但实际 epic 没跑,Claude 终审才发现 → review 链路里多浪费一轮 token + 一次延迟
- **协议级风险**:若 Claude 终审也 spot-check 不到位,模板占位符 epic 可能被错误标 CLOSED → 下游(M3-Beta-Scale / GA)以为 epic 已实测验证 → 撞「未验证的承诺」
- **类比 Finding #26**:state.md 反向膨胀漂移是「Agent 写多了」类协议偏离;本 finding 是「Agent 看少了」类——同样源于 starter 协议没把「应验证什么」**显式写明**
- **frequency**:任何 E2E / 真机 / 集成测试类切片都可能撞此模式(scripts 写完 ≠ 跑过)

## 根因

starter v5.1.0 `.ai/prompts/04-review.md`(Scout review)的检查清单 / 三步法主要关注:
1. AC 是否结构覆盖(brief 列的 acceptance 是否都有对应实现 / 测试 / 落档点)
2. Scope 越界(是否动了 brief 之外的文件)
3. 代码质量 / 协议 / 共享文件分工

**缺失**:
- ❌ 「**模板/占位符 vs 实测数据**」区分项 —— review 时看 `.log` 文件存在,但没看内容是 `{{VAR}}` 还是实测数字
- ❌ 「**脚本可跑 vs 已跑通**」区分项 —— 看到 `m3-beta-e2e.sh` 631 行设计完整就判 OK,没问「这脚本实际跑过几次?哪台真机?summary verdict 是什么?」
- ❌ 「**承接 deferred E2E 证据**」追踪项 —— 前序 RV(本 epic 中 RV-20260524-04 `fixed-with-deferred-E2E`)期望在本 epic 闭合时由 Verifier 转 verified,Scout 04-review 没主动 cross-check 前序 RV 是否得到承接

这些都是 E2E / 真机切片特有的检查项,与「单元测试 PASS」「代码 review」是不同维度。starter 现有 review checklist 用「代码 review 模板」复用到「E2E review」场景,粒度不够。

类比:#26(state.md 膨胀)和 #28(review 看不深)都属于「starter 协议没强制 explicit checklist 项,Agent 自由发挥下出现行为漂移」类。

## 证据

- DeviceOps M3-Beta S4 实施状态(2026-05-26):
  - `device-agent/scripts/m3-beta-e2e.sh` 631 行,`scripts/simulate-network-switch.sh` 111 行
  - `.ai/logs/m3-beta-e2e/scenario-{proto,4g-switch,config-hotload}.log` 全部含 `{{RUN_ID}} {{DATETIME}} {{FILE_ID}} {{LOGCAT_TORRENT_URL_HITS}}` 等占位符,无实测数据
  - state.md(Scout escalate 时刻)写 `Verdict: PASS · ESCALATE — 3 minor obs(非 blocking),epic-closeout 需 Claude 最终复审`
  - Claude 复审(同日)落档 `.ai/review.md > RV-20260526-01..04`,verdict = NEEDS-EXECUTION
- Scout 报告了 3 minor obs(scenario_proto return 缺 SHA / RESULT_ROOT 硬编码 / server_log 硬编码),全是代码细节;**没**raise「log 是占位符」这个一眼能看出的根本问题
- 触发链:Impl 写完脚本就刷 state.md `Impl ✅ · 04-review ✅` → Scout 三步法走完 → escalate → Claude 才 catch
- Claude 复审用 token ≈ 4.5k(独立判定 NEEDS-EXECUTION),如果 Scout 04-review 直接判 NEEDS-EXECUTION 可节省 Claude 一轮

## 提议修复

### 1. `.ai/prompts/04-review.md` 检查清单段追加

```markdown
##### E2E / 真机 / 集成切片专项检查(v5.2.x · Finding #28)

当被 review 的 task brief 含**真机 / E2E / 集成测试 / 端到端验证**类 acceptance 时,Scout 04-review **必须**额外校验三项(在三步法之外):

1. **模板 vs 实测数据**:对所有 `.log` / `.md` / `summary` 类落档文件,**grep 占位符模式**(`{{VAR}}` / `<TODO>` / `TBD`)。若命中,review verdict **不能直接 PASS**——必须 raise「`<path>` 内含 N 处模板占位符,实测数据未回填」作为 P1 finding(epic 不可 CLOSED)。
2. **脚本可跑 vs 已跑通**:对所有新增 / 修改的 E2E 脚本,**追问 progress.md / commit message / state.md**「这脚本实际跑过几次?哪台真机 serial?summary verdict 是什么?」。若**找不到实跑证据**,raise「`<script>` 设计完整但无实跑证据」作为 P1 finding。
3. **deferred 承接追踪**:cross-check `.ai/review.md` 是否有前序 RV 标记 `fixed-with-deferred-X` / Verifier verdict 注「待 epic Y 跑通后转 verified」。若有,**本 review 必须显式判断「epic Y 是否已承接」**;未承接则 escalate Claude(不能默默标 epic CLOSED)。

判定路径:
- 三项全 PASS + 其他 AC 全覆盖 → 走原 04-review 流程
- 任一项触发 P1 finding → verdict = **NEEDS-EXECUTION**(starter 协议新 verdict 值,**不**等同 PASS 或 REJECT),返回 Impl 执行后再 review

**反例(留底)**:DeviceOps M3-Beta S4 — Scout escalate PASS 但 3 个 scenario log 全 `{{VAR}}` 占位符,Claude 复审 spot-check 才发现,多消耗一轮 review token。
```

### 2. starter 协议层面:新增 `NEEDS-EXECUTION` verdict 值

现有 review verdict 集合 `PASS / PATCH / REJECT` 不能精确表达「设计 OK 但实测缺失」状态。建议在 starter v5.2.x 加第 4 个值:

| Verdict | 含义 | 下游动作 |
|---------|------|---------|
| `PASS` | 设计 + 实测都过 | epic 闭合 |
| `PATCH` | 有 finding 需修但不阻塞架构 | Impl 修 → 复 review |
| `REJECT` | 架构 / 决策错误 | 回 Claude 02-plan |
| **`NEEDS-EXECUTION`**(新) | 设计完整,真机 / E2E / 集成测试**未跑** | Impl 跑测试 + 回填证据 → 复 review |

`NEEDS-EXECUTION` 不是 fail(不要 demotivate Impl),也不是 PASS(防止 epic 误闭合)。

### 3. 同步更新 `.ai/prompts/05-claude-review.md`(若存在)

Claude 终审同样应主动 spot-check 占位符 + 实跑证据,作为 second line defense。但与 Scout 04-review 的区别:Claude **必须不替 Impl 跑真机**,只能判 NEEDS-EXECUTION 返回。

## 优先级建议

- P2 = 中优先;实战已撞坑(本 epic Scout escalate 误判)
- 与 Finding #26(state.md 膨胀)同类型(协议 explicit checklist 缺失)— 可并入 v5.2.x release
- lite v0.7.x 同步:Lead helper review 阶段加同等清单
- `NEEDS-EXECUTION` verdict 值的引入是协议级改动,影响 `state.md` template / `review.md` template / 各 prompt 收尾段;建议作为 v5.2.x 整体微 release 一并合入

---

## 实施记录(v5.3.0-rc1 · 2026-05-29)

- `.ai/prompts/04-review.md`:新增「E2E / 真机 / 集成切片专项检查」段(模板vs实测 / 脚本可跑vs已跑通 / deferred 承接追踪 三项)+「Verdict 第 4 值 `NEEDS-EXECUTION`」段(四值表 + 与 finding-25 Status 7 值的两轴区分)+ Small Task verdict 路径行 + 输出段 verdict 分支行同步补 NEEDS-EXECUTION。
- `.ai/state.md` template:`Next step` 校验规则加「verdict = NEEDS-EXECUTION → Next.Agent=Impl,不标 epic CLOSED」。
- `.ai/prompts/06-fix.md`:verdict 分支行补 NEEDS-EXECUTION。
- `.ai/workflow.md` §5.4:补 E2E 专项检查 + NEEDS-EXECUTION 指针。
- `05-claude-review.md`:**N/A**(v2.0 已删,Claude 复审是 main-session 协作,04-review 段已含 Claude 同样 spot-check 约束)。
- 关联 commit:见 CHANGELOG v5.3.0-rc1。
