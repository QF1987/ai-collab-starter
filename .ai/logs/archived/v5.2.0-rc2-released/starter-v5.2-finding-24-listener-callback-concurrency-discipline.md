---
finding-id: starter-v5.2-finding-24-listener-callback-concurrency-discipline
severity: P1
category: prompt (02-claude-plan 强约束)
source-project: DeviceOps
discovered: 2026-05-24
target:
  - .ai/prompts/02-claude-plan.md(强约束段加 Finding #24)
status: pending
related: [4]
---

# Finding 24: Listener / Observer / Callback 类决策必须显式规约并发实现纪律

## 现象

DeviceOps M3-Beta S2 中,ADR-20260523-02 D2 锁定「NetworkPolicy listener pattern」**架构**选择:
> `P2PDownloadManager` 持有 `std::shared_ptr<NetworkPolicy>`,**作为 listener 注册自身**——
> 网络切换时回调 `P2PDownloadManager::on_network_policy_changed()`

D2 锁了「用 listener pattern」这个架构层面,但**没规约**:
- listener callback 是在持锁内调还是解锁后调
- 是否必须 snapshot listeners 列表
- listener 反向调原对象时的锁序约束

Impl commit `38b84dd` 自由发挥,写成「持锁内遍历调 listener」:
```cpp
void NetworkPolicy::on_network_changed(NetworkType type) {
    std::lock_guard<std::mutex> lock(mu_);
    current_type_ = type;
    for (auto* listener : listeners_) {
        listener->on_network_changed(type);  // 持 NetworkPolicy::mu_ 调外部 callback
    }
}
```

并发 P2P 下载场景下:
- Thread A(worker)在 `P2PDownloadManager::run_download()` add_torrent 后块 → 持
  `P2PDownloadManager::mu_` → 调 `network_policy_->should_seed()` → 等 `NetworkPolicy::mu_`
- Thread B(ConnectivityManager 回调)→ `NetworkPolicy::on_network_changed()` → 持
  `NetworkPolicy::mu_` → 调 listener `P2PDownloadManager::on_network_changed()` → 等 `P2PDownloadManager::mu_`
- **ABBA 死锁**,Android Service 永久 hang

Claude 05-review 才发现 → 强制 P1 finding RV-20260524-02 → Impl 二次提交 `1d5d1f2` 改 snapshot 模式
(`listeners_` 拷贝到局部 vector → 释放 `mu_` → 解锁后遍历调)才闭合。

## 影响

- P1 级并发死锁实际进入了 commit history(被 Claude 05-review 拦截前差点放行到 S3)
- Beta E2E 场景 2(Wi-Fi ↔ 4G 切换)必然触发该 ABBA 路径(网络切换 + P2P 下载并行)— 生产 hang 风险
- 现有强约束 #1「决策必须唯一具体」覆盖了「不能让 Impl 在 A/B 之间选」,但**漏了**「锁了
  架构维度,漏锁实现维度」这个隐藏漂移空间
- Listener / observer / callback 是软件工程经典并发陷阱(不限 C++:Java synchronized 嵌套 /
  Kotlin coroutine / Go channel+mutex / Rust async / event-bus 都撞),启动器框架级缺失代价高

## 根因

starter v5.1.0 `02-claude-plan.md` 强约束 #1 处理的是**水平维度**(A/B/C 方案选择必须锁一个):
- 「不能让 Impl 在 listener / polling / push-based 之间选」→ 已覆盖

但 listener pattern 一旦锁定,**垂直维度**(同一架构选择内的实现纪律)还有多个隐藏决策:
- 持锁纪律:callback 在持锁内还是解锁后调
- snapshot 策略:是否拷贝 listeners 后释放锁
- 锁序约束:listener 反向调时是否允许反向锁
- listener 生命周期:裸指针 vs weak_ptr,悬挂引用处理

这些隐藏决策每个都有「正确做法 vs 自由发挥踩坑」,而 starter 现有约束**只防水平**,**不防垂直**。

类比:#22 处理「新增符号 grep 同包预检」是新增维度的纪律;本 #24 处理「锁定架构后实现规约」
是落地维度的纪律,二者互补。

## 证据

- ADR-20260523-02 D2 段(amendment 前)只锁架构,未锁实现:`DeviceOps/.ai/decisions.md > ADR-20260523-02`
- Impl commit `38b84dd` 实施持锁回调反模式:`device-agent/src/download/network_policy.cc` 原版
- Claude 05-review 发现 ABBA → RV-20260524-02(`DeviceOps/.ai/review.md` L1713 区)
- Impl commit `1d5d1f2` snapshot 修复:
  ```cpp
  std::vector<Listener*> listeners;
  {
      std::lock_guard<std::mutex> lock(mu_);
      current_type_ = type;
      listeners = listeners_;
  }
  for (auto* l : listeners) if (l) l->on_network_changed(type);
  ```
- Plan D2 amendment 后显式补「snapshot + 解锁后调」规约:`DeviceOps/.ai/plans/2026-05-23-m3-beta-p2p-engineering.plan.md` D2 段

## 提议修复

`.ai/prompts/02-claude-plan.md` 强约束段追加:

```markdown
##### Listener / Observer / Callback 类决策必须规约并发实现(v5.2.x · Finding #24 强约束)

当 ADR 锁定 listener pattern / observer pattern / callback 注册 / event-bus 类**架构选择**时,
**必须**在 Decision 段**同时锁定 4 项并发实现纪律**(防 Impl 自由发挥踩并发陷阱):

1. **调用纪律**:callback 是在持锁内调,还是释放锁后调?(推荐:**解锁后调**,除非有特殊理由)
2. **Snapshot 策略**:遍历 listeners 前是否必须先拷贝列表到局部容器,再释放锁?(推荐:**必须**)
3. **锁序约束**:listener 在 callback 内反向调原对象方法时,是否允许?如允许,描述锁序图
4. **生命周期纪律**:listener 用裸指针 / shared_ptr / weak_ptr?悬挂引用处理路径?

**禁止反模式**:
- 持锁内直接调外部 callback(可能 ABBA / 持锁阻塞 / mutex 递归 UB)
- 「让 Impl 自己决定 snapshot 策略」(等价 #1 决策漂移)
- 不写锁序图(等价默许 ABBA)

**通用模板**(snapshot + 解锁后调):
```cpp
void Subject::notify(Event e) {
    std::vector<Listener*> snapshot;
    {
        std::lock_guard<std::mutex> lock(mu_);
        update_state(e);          // 状态变更在持锁内
        snapshot = listeners_;     // 拷贝 listener 列表
    }                              // 释放锁
    for (auto* l : snapshot) if (l) l->on_event(e);  // 解锁后调
}
```

**反例(留底)**:DeviceOps M3-Beta ADR-20260523-02 D2 原锁「NetworkPolicy listener pattern」
未锁并发实现 → Impl 持锁回调 → ABBA 死锁(RV-20260524-02 P1)。
```

## 优先级建议

- P1 = 建议立即合入(`starter-upgrade-protocol.md`)
- 通用度高于 Finding #23(几乎所有 GUI / event-driven / 异步系统都用 callback pattern)
- lite v0.7.x 同步合入 Lead prompt
