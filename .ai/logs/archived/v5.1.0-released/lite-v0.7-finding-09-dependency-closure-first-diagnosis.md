---
finding-id: lite-v0.7-finding-09-dependency-closure-first-diagnosis
severity: P2
category: prompt + diagnostic-method-gap
source-project: smart-uite (bug-20260520-daemon-reader-device-prompt-loop · R1→R2 一次挖一个缺失依赖)
discovered: 2026-05-20
target:
  - .ai/prompts/02-codex-plan.md (诊断方法段加「依赖闭包优先」原则)
  - .ai/workflow.md (诊断循环收敛规则段同步)
status: pending
related: [F05-v0.6, F04-v0.6]
---

# Finding F09-v0.7: 缺「依赖闭包优先」诊断原则, linkage/missing-DLL 类 bug 一次只挖一个缺失依赖

## 现象

smart-uite `bug-20260520-daemon-reader-device-prompt-loop` epic (DcBusinessManager 反复弹「请接入读写器设备」), 诊断走了一次挖一个的链式过程:

- **初始 Decision (ADR-05)**: 判断缺 `DcReaderParam.ini` → workaround 补该文件 → **仍失败** (ADR-05 rejected)。
- **R1 (ADR-06)**: 复查发现 `EgAPP.dll` ABI 不对 (ReadBank 版覆盖了正确版, 不含 `EgAPP_Reader_OpenPortCall`) → workaround 换 DLL → 日志从「函数指针获取失败」推进为「动态库加载失败」 (ADR-06 rejected)。
- **R2 (ADR-07)**: 再复查发现新 `EgAPP.dll` 依赖 `MyLoggerCore.dll`, 而 `thirdparty/bin` 里的 `MyLoggerCore.dll` hash 也不对 → workaround 再换 → 解决。

也就是说: 根因是一个 **3 文件的依赖闭包问题** (`EgAPP.dll` + `MyLoggerCore.dll` + `DcReaderParam.ini` 同源 staging), 但诊断是一次只看一层, 挖了 3 轮 ADR (2 个被 reject)。

## 影响

- **诊断成本不对称**: 最终修复就是 `StageTdmRuntime.cmake` 固定 3 个文件的同源 staging。但因为没有一开始就做完整的传递依赖闭包扫描, 花了 3 轮 ADR + 2 次 workaround 验证失败。
- **每轮只暴露下一层**: 补 A → 暴露 B 缺失 → 补 B → 暴露 C 缺失。这是 linkage / DLL-resolution 类 bug 的典型形态, 但 lite 02-plan 没有针对性方法论。
- **生产环境放大**: derived 项目 (C++ 系统 / native DLL bundle) 这类 bug 很常见, 没有「闭包优先」原则就会反复链式烧轮次。

## 根因

`02-codex-plan.md` v0.6 已有 F05-v0.6「differential signal 优先」诊断原则 (针对 PASS/FAIL 分化), 但**没有针对 linkage / missing-symbol / missing-DLL 类 bug 的「传递依赖闭包优先」原则**。

对这类 bug, 第一轮就该做完整闭包扫描 (`dumpbin /dependents` 递归 / `ldd` / import table 全解析), 把所有缺失/ABI 不符的依赖一次列全, 再出一个覆盖整个闭包的 Decision——而不是补一个看下一个。

## 证据

- smart-uite `bug-20260520-daemon-reader` 会话归档 §3-5: ADR-05 (缺 `DcReaderParam.ini`) rejected → ADR-06 (`EgAPP.dll` ABI) rejected → ADR-07 (3 文件闭包) accepted。
- 同归档 §5: R2 才发现「新 `EgAPP.dll` 依赖 `MyLoggerCore.dll`」——这个依赖关系 `dumpbin /dependents` 第一轮就能看到。
- 同归档 §11 结论: 最终修复是固化 `EgAPP.dll` / `MyLoggerCore.dll` / `DcReaderParam.ini` 同源闭包 staging。

## 提议修复

### 1. `02-codex-plan.md > 诊断型 epic 强约束` 加「依赖闭包优先」原则

```markdown
### 诊断方法: 依赖闭包优先 (linkage / missing-DLL 类 bug · v0.7 · F09-v0.7)

bug 现象指向「找不到符号 / 动态库加载失败 / 函数指针获取失败 / undefined reference」类
linkage 问题时, 诊断第一轮**必须先做完整传递依赖闭包扫描**, 而非补一个看一个:

1. 对嫌疑二进制跑递归依赖扫描 (`dumpbin /dependents` 递归 / `ldd` / PE import table 全解析),
   列出**整条依赖链**的每个节点。
2. 对链上每个节点核对: 文件是否存在 / hash 是否同源 / ABI 导出符号是否匹配。
3. 一次性把闭包内所有缺失/不符项列全, 出一个**覆盖整个闭包**的 Decision (含 staging 顺序)。

禁止: 补一个缺失依赖 → 跑 → 看下一个缺失依赖 → 再补 (链式烧轮次)。
该闭包扫描算「强收敛」, 满足 F04-v0.6 诊断轮次放宽条件。
```

### 2. `workflow.md > 诊断循环收敛规则` 段同步「闭包扫描 = 强收敛」定义

与 F05-v0.6 的 differential signal 段并列维护。

## SemVer 影响

**MINOR** (新增诊断方法论原则 · 不破坏 v0.6 旧 epic · 纯增量指引)。

## 关联

- 与 **F05-v0.6 (differential signal 优先)** 同属诊断方法论: F05 针对 PASS/FAIL 分化, F09 针对 linkage 链式缺失, 互补。
- 与 **F04-v0.6 (诊断轮次上限)** 协同: F09 让 linkage 类 bug 第一轮就闭包收敛, 减少轮数。
- 跨 epic 历史: smart-uite 是 C++ native DLL bundle 系统, 此前 `qt5core-missing` / `h5coat` 等 epic 也有 DLL-resolution 形态, F09 把方法论沉淀下来。

---

## v0.7 实施记录 (2026-05-20)

本 finding 在 `v0.7.0-lite-rc1` release 消化。实施详情见 `CHANGELOG.md` `[v0.7.0-lite-rc1]` 段。

---

## main v5.1.0-rc1 处置 (2026-05-20)

**采纳** — 已翻译实施到 main 契约。详见 main `CHANGELOG.md` `[v5.1.0-rc1]` 段。
