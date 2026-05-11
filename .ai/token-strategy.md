# Token Strategy

## Goals

- Reduce repeated full-repo scans.
- Spend Claude tokens only on high-value reasoning.
- Keep Codex implementation context bounded.
- Let OpenCode and lower-cost models prepare context and reviews.
- Preserve reusable knowledge in Markdown.

## Layered Context

Use context in this order:

1. `AGENTS.md`: global operating rules.
2. `.ai/context.md`: stable project map.
3. `.ai/architecture.md`: boundaries and review triggers.
4. `.ai/decisions.md`: accepted decisions.
5. `.ai/plan.md` or `.ai/tasks/<task>.md`: current scope.
6. Source files: only paths required by the task.

## Reducing Context

- Ask OpenCode for a file map before asking Claude for design.
- Summarize large modules instead of pasting full files.
- Prefer symbols, paths, call chains and test names over raw source.
- Use `rg` or GitNexus queries with scoped terms.
- Read direct callers/callees, not every file in the same repo.
- Use GitNexus `contracts`, `context`, `impact` and `detect-changes` instead of ad hoc whole-repo exploration.

## Splitting Sessions

Split when:

- The task touches more than one repo.
- The task changes protocol or storage semantics.
- The conversation exceeds one coherent feature or bug.
- Claude has produced a decision and Codex is ready to implement.
- Review findings need a separate fix pass.

Each split should leave a task file with goal, paths, decisions, tests and next step.

## Limiting Directory Scans

仓库目录入口以 `.ai/context.md > Repo Map` 为准。本文件只补充扫描预算原则：

- 任务未指明范围时，最多扫描 1 个一级子目录后必须停下要 scope。
- 协议任务必须同时打开两侧 `proto/terminal_agent/v1/`，但只读到与目标 service/message 直接相关的文件。
- Android 任务默认不扫 C++；C++ 任务默认不扫 Android。除非任务涉及 JNI、打包或服务生命周期。

## Avoiding Long Conversations

- Convert conclusions into `.ai/tasks/<task>.md`.
- Move durable decisions into `.ai/decisions.md`.
- Move review findings into `.ai/review.md`.
- Start a new session when implementation begins after architecture approval.
- Do not make Claude re-read implementation output that OpenCode can summarize.

## Agent Boundaries

OpenCode:

- Best for broad but cheap scanning, doc generation, symbol maps and low-cost review.
- Should output concise context packets with file paths and risks.

Claude Code:

- Best for architecture, complex root cause, trade-offs and critical review.
- Should receive a narrow question and prepared context packet.

Codex:

- Best for editing files, fixing tests, wiring build scripts and running verification.
- Should receive exact repo, paths, task file, acceptance criteria and test commands.

## Prompt Budget Rules

- Include only the current task file and changed-file list when asking for implementation or review.
- Do not paste generated logs unless the key error lines are unclear.
- Use bullets and tables instead of long narratives.
- Name what not to inspect.
- Cap each Agent output to the smallest artifact that moves the workflow forward.
