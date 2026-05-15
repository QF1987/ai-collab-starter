---
finding: starter-v2-finding-03
slug: technical-decision-no-fallback
date: 2026-05-13
severity: P1
---

# Finding 03 — 技术选型题缺少「用户不懂，agent 拍板」的显式分支

## 现象

intake 问 ORM 选型（MyBatis vs JPA），用户回答「你定吧，我对这两种不太懂」。

当前 intake 流程只有三种预设回答模式：
1. 用户选 A / B / C（清楚知道选什么）
2. 用户说「TBD」（知道不确定）
3. 用户不回答（intake 纪律说"停下等答案"）

没有针对「用户明确授权 agent 拍板技术细节」的显式处理路径。
agent 需要自行判断"这算授权拍板还是需要逼用户回答"，有歧义。

## 影响

- 若 agent 保守 → 继续追问用户不懂的问题（死锁）
- 若 agent 激进 → 自行决定但没记录决策理由（[推断] 标识不够）
- 正确做法是：agent 解释推荐理由 + 给出决定 + 标 [推断:agent-decision]
  但这个路径在 intake-templates 和 SKILL.md 里都没有明文规定

## 建议

在 `intake-templates.md > §A Task Intake > 问题流` 末尾增加说明：

```
技术选型类题（如 ORM/框架/协议选择）：
  - 若用户说"你定" / "随便" / "帮我选" → agent 直接给出推荐 + 理由
    并标记为 [agent-decision] 前缀（比 [推断] 更强的意图标识）
  - 并在 decisions.md ADR 的 Owner 字段写 "Claude (intake)"
  - 不需要再问用户确认（既然已经授权）
```

并在 SKILL.md 里对应更新「第 1 步 · 按分支问问题」中的「用什么提问」段。

## 严重度

P1 — 明显摩擦。技术选型类问题在批处理域（框架/调度器/数据访问层）尤其频繁。
这也是本项目作为 Java/批处理异构靶子特别能暴露的场景：
Go 项目很少需要「选 ORM」这类问题（Go 生态 ORM 相对简单），
Java Spring Boot 必问。
