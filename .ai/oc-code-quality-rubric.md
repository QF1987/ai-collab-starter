# OC 代码质量 rubric (lite v0.1.0)

## 用途

Codex 03c 验收 OC-impl 产出时, 按本 rubric 打分。

**统一门槛: 总分 ≥ 16/24 通过**, 不分核心/glue。
(slice 类型在 brief 里 Codex 已标注, 当上下文给打分用, 不分门槛)

## 适用阶段

- Codex 03c 验收(主要场景)
- OC-review 04 三步法第三步辅助参考(交叉验证 03c 是否偷工)
- lite-upgrade-protocol Step 4 实施时同样适用

## 流程

```
1. 硬门槛 H1-H5 逐条 check
   任一 fail → 直接退回 OC-impl, 不打分
2. 维度 D1-D8 逐项打分 (每维 0-3 分, 总分 24)
   总分 ≥ 16/24 通过, < 16 退回
3. 通过 → state.md 进 04;
   退回 → 输出"退回模板"喂回 OC-impl (轮次 +1)
```

## 硬门槛 (任一不过 → 直接退回, 不打分)

- [ ] **H1**. pre-decisions (brief frontmatter) 无一条被违反
  - 验证方法: 对 frontmatter 每条 D 找 diff 中是否动了相关代码 / 接口 / 决策
  - 典型 fail 信号: D2 锁"不引入新依赖", OC-impl 在 package.json 加了 lodash
- [ ] **H2**. paths 二组分: OC-impl 只动了"核心 paths" + 子任务包明确许可的"连带 paths"
  - 验证方法: `git diff --cached --stat`, 逐行核对每个文件路径都在子任务包 paths 列表内
  - 典型 fail 信号: 改了 `src/utils/format.ts` 但子任务包 paths 没列
- [ ] **H3**. 编译 / lint / typecheck 通过 (Codex 本机跑)
  - 验证方法: 跑子任务包"测试要求"段指定的命令
- [ ] **H4**. 现有测试不退化 (新增测试可以失败, 但旧测试不能挂)
- [ ] **H5**. 无可疑大段改动: 单文件 diff > 200 行 → 自动 fail (除非子任务包显式预声明)
  - 验证方法: `git diff --cached --numstat | awk '$1+$2 > 200'`

## 维度打分 (每维 0-3 分, 8 维度, 总分 24, 门槛 ≥ 16/24)

| 维度 | 0 (fail) | 1 (差) | 2 (合格) | 3 (好) |
|------|---------|--------|---------|--------|
| **D1. brief 完成度** | 漏关键需求 | 完成 60-80% | 100% | 100% + 边界全覆盖 |
| **D2. 代码可读性** | 命名/结构混乱 | 能读懂但啰嗦 | 清晰直接 | 简洁且自解释 |
| **D3. 测试质量** | 无/假测试 | 只 happy path | + 1-2 边界 | + 错误路径 |
| **D4. 边界/错误处理** | 未处理 | 部分处理 | 关键边界处理 | 显式 + 注释了为什么 |
| **D5. 不越界** | 大量无关改动 | 1-2 处可疑 | 紧贴 brief | + 删了死代码 |
| **D6. 注释克制** | 过度/废话注释 | 略多 | 只在 why 不明显处加 | 零废话注释 |
| **D7. 安全性** | 注入/越权/明文密钥 | 缺输入校验 | 输入校验 + 边界 OK | + 依赖审过, 无新增漏洞面 |
| **D8. 性能** | 明显 N+1 / O(n²) 误用 | 无意识低效 | 合理实现 | + 注释了复杂度选择 |

## 退回模板 (Codex 03c → OC-impl)

```
Verify 不通过. 原因:
- [hard fail 列表 / 或维度低分理由]
  e.g. H1 pre-decisions 违反: D2 锁"不引入新依赖", OC-impl 在 package.json 加了 lodash
  e.g. D5 不越界 = 0: OC-impl 改了 brief 未列的 src/utils/format.ts

修改要求:
1. 回退 package.json 改动, lodash 不引入 (D2)
2. 回退 src/utils/format.ts 改动 (paths 越界)
3. 完成原必做项

保留 (OC-impl 做对的地方, 显式列出, 避免它推倒重来):
- src/service/user.ts:create() 逻辑正确, 保持
- 单测 user.test.ts:happy path 写得清晰, 保持

轮次: X/3 (超过 3 轮升 Human 决策)
- 若 X<3: 请按上述修改, 提交后重新 done
- 若 X=3: 不要再改了, 请输出"达到 3 轮上限, 升 Human 决策"
```

## 维度低分常见模式速查

(给 Codex 03c 参考, 加快打分)

### D1 fail 信号
- 子任务包列了 5 条必做, OC-impl 只实现了 3 条
- 子任务包 AC "返回 4xx 当输入非法", 实际只校验了 happy path

### D3 fail 信号
- 测试名 `TestFoo` 但断言只检查 `err == nil` 不验证业务字段
- 用 mock 把整个被测函数 mock 掉了 (假测试)
- 测试只跑 happy path, 没有任何边界

### D4 fail 信号
- 缺 nil check 但访问 nil 字段
- 错误吞掉 (`_ = err`) 没 log / wrap
- 并发场景缺锁 / channel close 时机不对

### D5 fail 信号
- 单文件 diff 行数远超合理估计 (e.g. 改一个函数动了 100 行)
- 动了 brief 没列的 import / package 重排
- "顺手"重命名了无关变量

### D6 fail 信号
- 注释 `// increment i` 在 `i++` 旁边
- 注释里写"为什么"但其实写了"做什么"
- TODO / FIXME 没有 issue 编号

### D7 fail 信号
- SQL 字符串拼接 (注入风险)
- 文件路径未规范化 (path traversal)
- 硬编码 token / secret
- 错误信息漏 stack trace 给用户

### D8 fail 信号
- 循环内 DB 查询 (N+1)
- sync 写文件在 hot path
- 大 map 用线性查找
- 不必要的全表加载

## 与 main rubric 的对比

main v4.0-rc1 没有独立 rubric 文件, 用 04-opencode-review.md 的三步法做 quality 检查。
lite 引入独立 rubric 因为:

- Codex 03c 是 Codex **自审** OC 产出, 需要更结构化的标准防漏检
- OC 是国产模型, 训练数据偏弱, 需要更明确的"过线"门槛
- 8 维度涵盖 main v4.0-rc1 三步法 quality 段的所有子项 + 安全 + 性能两维

## v0.1.0 后的迭代方向 (附录)

- D7/D8 在不同语言生态下"合格"标准不同 → v0.2.0 考虑按语言自适应启用子项 (类似 04 prompt repo-自适应那张表)
- 门槛 16/24 是经验值, 跑通 3 个真实 epic 后看是否需要分类型调 (Tiny 12/24 / Medium 16/24 / Large 18/24?)
- 退回模板"保留"段是否真的防 OC 推倒重来——v0.2.0 加自动检测 (前后两轮 diff 重叠率)
