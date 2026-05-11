# AI Collaboration Workflow

This workflow turns requirements into reviewed, testable changes while preserving context across long-lived multi-repo development.

## 1. Requirement

Owner: human or product/engineering lead.

Output:

- Goal
- Non-goals
- Affected repos
- Expected behavior
- Constraints
- Acceptance criteria

For substantial work, create `.ai/tasks/<date>-<slug>.md`.

## 2. Analysis

Owner: OpenCode.

Inputs:

- `AGENTS.md`
- `.ai/context.md`
- `.ai/architecture.md`
- task file
- scoped paths or symbols

Output:

- Relevant files and symbols
- Existing behavior
- Tests/build commands
- Risks and unknowns
- Suggested Claude questions, if architecture is needed

Rules:

- Analysis must be scoped. Avoid full-repo scans unless justified.

## 3. Architecture

Owner: Claude Code.

Inputs:

- OpenCode context packet
- task file
- relevant `.ai/decisions.md` entries
- minimal source excerpts or file references

Output:

- Decision
- Alternatives
- Compatibility constraints
- Implementation slices
- Review focus
- Tests and acceptance criteria

Record accepted decisions in `.ai/decisions.md`.

## 4. Implementation

Owner: Codex.

Inputs:

- task file
- accepted architecture decision, if any
- exact repo and path scope
- test commands

Output:

- Minimal code patch
- Updated docs or generated files, if required
- Targeted test results
- Progress entry

Rules:

- Implement one slice at a time.
- Do not expand scope to adjacent cleanup.
- Do not alter architecture without returning to Claude review.
- For cross-repo protocol changes, update both sides in a planned order.

## 5. Review

Owner: OpenCode first, Claude Code when risk warrants it.

OpenCode review:

- changed-file scan
- obvious correctness issues
- missing tests
- docs drift
- generated-code drift
- style consistency

Claude review:

- architecture correctness
- protocol compatibility
- failure modes
- concurrency and lifecycle
- security and fleet rollout risk
- long-term maintainability

Output goes to `.ai/review.md` or the task file.

## 6. Fix

Owner: Codex.

Inputs:

- accepted review findings
- changed-file list
- failing tests or CI logs

Output:

- Focused fixes
- Re-run tests
- Updated review status

Rule: Codex fixes approved findings only. New architecture issues return to Claude.

## 7. Merge

Owner: human or repo maintainer, assisted by Codex.

Checklist:

- GitNexus `detect-changes` run in changed repos.
- Targeted tests pass or skipped tests are documented.
- `.ai/progress.md` includes changed files and verification.
- `.ai/review.md` has no unresolved blocking findings.
- Commit scope is small and repo-specific.
- PR description includes behavior, tests, risks and rollback notes.

## CI/CD Extension

This framework can be extended by adding:

- `.ai/tasks/<task>.md` generated from issue templates.
- CI job summary copied into `.ai/logs/` and summarized in `.ai/progress.md`.
- OpenCode review prompt run on changed files in PR.
- Claude review prompt run only on high-risk labels.
- Codex fix prompt used for failed CI or accepted review findings.
