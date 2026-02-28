---
name: forge-workflow
description: Execute Forge's Linear-integrated, SOC2-friendly development workflow from Codex.
metadata:
  short-description: Forge workflow for Codex
---

# Forge Workflow (Codex)

Use this skill when a user asks for Forge-style workflows such as:
- `/forge:start`
- `/forge:load`
- `/forge:finish`
- `/forge:fix-pr`
- `/forge:fix-compliance`
- `/forge:audit`
- `/forge:verify-pr`
- `/forge:cleanup`
- `/forge:hotfix`
- `/forge:release`
- `/forge:add-tests`
- `/forge:new-issue`
- `/forge:capture`
- `/forge:worktree`
- `/forge:suggest-cleanups`

## Purpose

Bring the existing Forge process to Codex without changing workflow intent.
This skill maps to bundled Forge command specs under `references/commands/`.

## Source of Truth

Treat these files as authoritative:
- `references/commands/start.md`
- `references/commands/load.md`
- `references/commands/finish.md`
- `references/commands/fix-pr.md`
- `references/commands/fix-compliance.md`
- `references/commands/audit.md`
- `references/commands/verify-pr.md`
- `references/commands/cleanup.md`
- `references/commands/hotfix.md`
- `references/commands/release.md`
- `references/commands/add-tests.md`
- `references/commands/new-issue.md`
- `references/commands/capture.md`
- `references/commands/worktree.md`
- `references/commands/suggest-cleanups.md`
- `references/commands/update-docs-toc.md`
- `references/commands/release-media.md`
- `references/commands/update-domain-docs.md`
- `references/commands/help.md`

Use `references/command-map.md` for fast command routing.

## Codex Adaptation Rules

1. Keep Forge workflow semantics intact.
2. When Forge docs say `AskUserQuestion`, ask the user directly in chat and continue.
3. When Forge docs mention Claude-only plugin commands, run equivalent shell/MCP/API steps in Codex and note any gaps.
4. Replace Claude-specific task list instructions with Codex planning (`update_plan`) when needed.
5. Prefer non-destructive git operations; never run destructive commands unless user explicitly asks.
6. Preserve SOC2 traceability expectations: Linear ticket linkage, scope alignment, and audit trail.
7. If a required integration is missing (Linear MCP, GitHub auth, plugin), report blocker and continue with best-effort fallback.

## Quick Routing

- User asks to start ticket work: follow `references/commands/start.md`
- User asks to load/spec a ticket: follow `references/commands/load.md`
- User asks to finalize before push/PR: follow `references/commands/finish.md`
- User asks to handle CodeRabbit/Greptile/Aikido findings: follow `references/commands/fix-pr.md`
- User asks to fix CI compliance failures: follow `references/commands/fix-compliance.md`
- User asks compliance status only: follow `references/commands/audit.md`
- User asks to build PR compliance doc: follow `references/commands/verify-pr.md`
- User asks post-merge cleanup: follow `references/commands/cleanup.md`
- User asks to document a hotfix: follow `references/commands/hotfix.md`
- User asks to release to production: follow `references/commands/release.md`
- User asks to generate tests: follow `references/commands/add-tests.md`
- User asks to create a new issue: follow `references/commands/new-issue.md`
- User asks to capture planning into a ticket: follow `references/commands/capture.md`
- User asks to create a worktree: follow `references/commands/worktree.md`
- User asks to clean up old branches/worktrees: follow `references/commands/suggest-cleanups.md`

## Expected Repo Conventions

- `.forge` at repo root with worktree config
- `.mcp.json` for MCP servers
- `issues/` for product requirements
- `specs/` for technical specs
