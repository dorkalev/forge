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

Bring the existing Forge process to Codex without changing how the workflow behaves.
This skill maps to the same command specs under `commands/`.

## Source of Truth

Treat these files as authoritative:
- `../../commands/start.md`
- `../../commands/load.md`
- `../../commands/finish.md`
- `../../commands/fix-pr.md`
- `../../commands/audit.md`
- `../../commands/cleanup.md`
- `../../commands/verify-pr.md`
- `../../commands/help.md`

Use `references/command-map.md` for fast command routing.

## Codex Adaptation Rules

1. Keep the Forge workflow semantics intact.
2. When Forge docs say `AskUserQuestion`, ask the user directly in chat and continue.
3. When Forge docs mention Claude-specific plugin commands, run equivalent shell/API steps in Codex and explicitly note any gaps.
4. Prefer non-destructive git operations; never use destructive commands unless the user explicitly asks.
5. Keep SOC2 traceability expectations: Linear ticket linkage, scope alignment, audit trail.
6. If a required external integration is missing (Linear MCP, GH auth, plugin), report the blocker and continue with best-effort fallback.

## Quick Routing

- User asks to start work on issue: follow `start.md`
- User asks to load/spec an issue: follow `load.md`
- User asks to finalize before push/PR: follow `finish.md`
- User asks to handle CodeRabbit comments: follow `fix-pr.md`
- User asks compliance status only: follow `audit.md`
- User asks post-merge cleanup: follow `cleanup.md`

## Expected Repo Conventions

- `.forge` at project root with worktree config
- `.mcp.json` for MCP servers
- `issues/` for product requirements
- `specs/` for technical specs

