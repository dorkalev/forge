---
description: Check SOC2 compliance status for current branch (read-only)
---
# /audit - SOC2 Compliance Status Check

Read-only check. Makes NO changes.

**Prerequisites**: Linear MCP configured in `.mcp.json`

## Checks

1. **Issue File**: `issues/{ISSUE_ID}.md` matching branch (e.g., `proj-123-feature` → `PROJ-123.md`). Has Summary + Acceptance Criteria? PASS/WARN/FAIL.
2. **Spec File**: `specs/{feature}.md` related to branch. Has technical details? PASS/WARN/FAIL.
3. **Spec Alignment**: `git diff staging...HEAD --name-only` vs spec documentation. PASS/WARN (N files not in spec).
4. **Tests**: Test files exist for feature, tests pass. PASS/WARN (no tests)/FAIL (tests failing).
5. **Linear Issue**: Extract ID from branch, `linear_search_issues(query, limit: 1)`. Exists, state appropriate. PASS/WARN (no PR link)/FAIL (not found).
6. **PR Status**: `gh pr list --head <branch> --base staging`. Has Linear issue table. PASS/WARN/FAIL.
7. **PR Body Completeness**: Has `## TL;DR`, `## Product Requirements` (Summary + Acceptance Criteria), `## Technical Implementation`, `## Testing & Verification`. All criteria verified with Status + Verification columns. PASS/WARN (missing optional: Out of Scope, Notable Decisions, Audit Trail)/FAIL (missing required or unverified).
8. **Secrets Check**: `git diff staging...HEAD` — scan for API keys, tokens, passwords, .env values. PASS/FAIL.

## Output
```
SOC2 Compliance Audit: {BRANCH-NAME}
======================================================================
Issue File          {status} {details}
Spec File           {status} {details}
Spec Alignment      {status} {details}
Tests               {status} {details}
Linear Issue        {status} {details}
PR Status           {status} {details}
PR Body Complete    {status} {details}
Secrets Check       {status} {details}
----------------------------------------------------------------------
Overall: {READY | NOT READY} for /finish
{If not ready, list what needs addressing}
```
