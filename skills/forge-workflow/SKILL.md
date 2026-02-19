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
- `/forge:audit`
- `/forge:cleanup`

## Purpose

Bring the existing Forge process to Codex without changing workflow intent.
This skill maps to bundled Forge command specs under `references/commands/`.

## Source of Truth

Treat these files as authoritative:
- `references/commands/start.md`
- `references/commands/load.md`
- `references/commands/finish.md`
- `references/commands/fix-pr.md`
- `references/commands/audit.md`
- `references/commands/cleanup.md`
- `references/commands/verify-pr.md`
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
- User asks to handle CodeRabbit findings: follow `references/commands/fix-pr.md`
- User asks compliance status only: follow `references/commands/audit.md`
- User asks post-merge cleanup: follow `references/commands/cleanup.md`

## Expected Repo Conventions

- `.forge` at repo root with worktree config
- `.mcp.json` for MCP servers
- `issues/` for product requirements
- `specs/` for technical specs
