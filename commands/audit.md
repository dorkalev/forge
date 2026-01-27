---
description: Check SOC2 compliance status for current branch (read-only)
---

# /audit - SOC2 Compliance Status Check

You are a SOC2 Compliance Auditor. Verify that the current branch meets all compliance requirements before merge. This is a **read-only** operation.

**Prerequisites**: Linear MCP server must be configured in `.mcp.json`

## Usage

```
/audit
```

## What You Check

### 1. Issue File
- Look for `issues/{ISSUE_ID}.md` matching the branch name (e.g., `proj-123-feature` -> `PROJ-123.md`)
- Verify it contains: Summary, Acceptance Criteria
- Report: PASS exists with content, WARN incomplete, FAIL missing

### 2. Spec File
- Look for `specs/{feature-name}.md` related to the branch
- Check it contains technical implementation details
- Report: PASS exists, WARN outdated, FAIL missing

### 3. Spec Alignment
- Get changed files: `git diff staging...HEAD --name-only`
- Compare against what's documented in spec
- Report: PASS aligned, WARN N files not in spec

### 4. Tests
- Check if test files exist for the feature
- Run tests if they exist
- Report: PASS N tests passing, WARN no tests found, FAIL N tests failing

### 5. Linear Issue Status
- Extract issue ID from branch name
- Use Linear MCP to check:
  ```
  linear_search_issues(query: "PROJ-XXX", limit: 1)
  ```
- Verify: issue exists, state is appropriate (In Progress, In Review)
- Report: PASS linked, WARN no PR link, FAIL issue not found

### 6. PR Status
- Find PR: `gh pr list --head <branch> --base staging`
- Check PR description contains Linear issue table
- Report: PASS has issue table, WARN missing issue table, FAIL no PR found

### 7. PR Body Completeness (SOC2 Audit Record)
- Check PR body contains required sections for self-contained audit record:
  - **TL;DR section**: `## TL;DR` present
  - **Product Requirements section**: `## Product Requirements` present with Summary and Acceptance Criteria
  - **Technical Implementation section**: `## Technical Implementation` present
  - **Testing & Verification section**: `## Testing & Verification` present
  - **Acceptance Criteria verification**: All criteria in table have Status and Verification columns filled
- Report:
  - PASS: All sections present, all criteria verified
  - WARN: Missing optional sections (Out of Scope, Notable Decisions, Audit Trail)
  - FAIL: Missing required sections or unverified criteria

### 8. Secrets Check
- Scan diff: `git diff staging...HEAD`
- Look for: API keys, tokens, passwords, .env values
- Report: PASS clean, FAIL potential secrets detected

## Output Format

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
{If not ready, list what needs to be addressed}
```

### PR Body Completeness Details

When checking PR body completeness, report section-by-section:

```
PR Body Completeness:
  [x] TL;DR section present
  [x] Linear Tickets table
  [x] Product Requirements section
      [x] Summary
      [x] Acceptance Criteria (5 items, all verified)
      [x] Out of Scope
  [x] Technical Implementation section
      [x] Architecture Summary
      [x] Key Changes table
  [x] Testing & Verification table
  [ ] Audit Trail section (optional)
```

## Status Icons
- PASS = Pass
- WARN = Warning (can proceed but should address)
- FAIL = Fail (must fix before /finish)

## Important Notes

1. **Read-only**: Makes NO changes to files, commits, or external systems
2. **Quick**: Should complete in seconds
3. **Honest**: Report actual status
4. **Actionable**: Note what needs to be done for each issue
