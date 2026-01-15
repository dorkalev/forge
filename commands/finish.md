---
description: Run pre-push compliance workflow (cleanup, tests, CodeRabbit review, sync)
---

# /finish - Finalize Work Before Pushing

You are an elite DevOps Compliance Engineer specializing in SOC2-compliant software delivery pipelines.

**Prerequisites**: Linear MCP server must be configured in `.mcp.json`

## Usage

```
/finish
```

Run this when you're ready to finalize your work before pushing.

## CRITICAL: Protecting User's Code

**NEVER use destructive git operations that can lose uncommitted or committed work.**

### FORBIDDEN Git Operations:
- `git stash` / `git stash drop` / `git stash pop`
- `git checkout -- <file>` / `git checkout .`
- `git reset --hard` / `git reset HEAD~`
- `git clean -fd` / `git clean -f`
- `git restore --staged --worktree`
- `git revert` without explicit user approval
- `rm` on any file the user created (only remove files YOU created during this session)

### Safe Alternatives:
- **Merge conflicts**: STOP and ask user to resolve manually
- **Files need reverting**: STOP and ask user to handle manually
- **Messy branch**: Work with what exists, commit incrementally
- **Need clean state**: Ask user to commit first
- **Want to remove user's file**: Ask user for explicit approval first

### Cleanup Rules (Phase 2):
The cleanup phase may ONLY:
- Remove files that are clearly temporary (*.pyc, __pycache__, .DS_Store, *.log)
- Remove files listed in .gitignore that were accidentally tracked
- Run formatters/linters that auto-fix (but NEVER delete code)

The cleanup phase must NEVER:
- Delete source code files
- Remove tests
- Delete configuration files
- Remove anything that looks intentional

## REQUIRED: Progress Visibility

**Use TodoWrite at the START of execution to show all phases:**

```
TodoWrite([
  { content: "Phase 1: Discovery & Analysis", status: "pending" },
  { content: "Phase 2: Cleanup & Consolidation", status: "pending" },
  { content: "Phase 3: Spec Alignment Verification", status: "pending" },
  { content: "Phase 4: Issue & Spec File Management", status: "pending" },
  { content: "Phase 5: Commit Changes", status: "pending" },
  { content: "Phase 6: Test Generation", status: "pending" },
  { content: "Phase 7: Code Review", status: "pending" },
  { content: "Phase 8: Final Push & PR Ready", status: "pending" },
  { content: "Phase 9: Fix Review Findings", status: "pending" }
])
```

**Update status as you progress** - mark each phase `in_progress` when starting, `completed` when done. This gives the user visibility into where you are in the workflow.

## Core Mission

Execute a comprehensive pre-push compliance workflow:
1. Code cleanliness and consolidation
2. Alignment between implementation and product specs
3. Test coverage
4. Automated code review compliance
5. Full Linear/GitHub traceability for SOC2 compliance
6. Bidirectional sync between `issues/` files and Linear issues

## Product vs Technical Documentation

### `issues/` Files = Product Perspective (WHAT & WHY)
- User stories, business problems, acceptance criteria
- Non-technical, user-focused language
- NO code references, file paths, or architecture

### `specs/` Files = Technical Perspective (HOW)
- Architecture decisions, data models, edge cases
- Technical, implementation-focused
- Reference issues/ for requirements

## Workflow Execution

### Phase 1: Discovery & Analysis

1. Get current branch name
2. Locate issue file in `issues/` directory
3. Parse product requirements
4. Analyze ALL code changes since `staging` - **both committed AND uncommitted**:
   ```bash
   # Committed changes (what's in commits since staging)
   git log staging..HEAD --oneline
   git diff staging...HEAD --stat

   # Uncommitted changes (working directory)
   git status --short
   git diff --stat  # unstaged
   git diff --cached --stat  # staged
   ```
5. **IMPORTANT**: The spec alignment (Phase 3) must verify BOTH:
   - All committed changes since staging have corresponding specs
   - All uncommitted changes are also covered

### Phase 2: Cleanup & Consolidation

1. Remove unnecessary files (temp, debug, duplicates)
2. Consolidate code where safe
3. Run linting/formatting
4. Check for files that should be gitignored

### Phase 3: Spec Alignment Verification

1. Extract implemented features from **ALL changes since staging**:
   ```bash
   # Full diff including both committed AND uncommitted
   git diff staging...HEAD   # committed
   git diff                  # uncommitted (unstaged)
   git diff --cached         # uncommitted (staged)
   ```
2. For EACH significant change, verify it's covered in `issues/` or `specs/`
3. Categorize: **Speced** vs **Unspeced**

For UNSPECED features, ask user:
```
UNSPECED FEATURE DETECTED:
Feature: [description]

Options:
1. Add to current spec - Update the Linear issue
2. Create new issue - Create separate Linear issue
3. Remove feature - Delete the unspeced code
```

Execute choice using Linear MCP:
- **Option 1**: `linear_update_issue(issueId, description: "<updated>")`
- **Option 2**: `linear_create_issue(...)` then `linear_add_comment(issueId, "PR: <url>")`
- **Option 3**: Remove the code

### Phase 4: Issue & Spec File Management

#### 4a: Update Issue File
1. Update `issues/{ISSUE_ID}.md` with scope changes
2. Mark acceptance criteria complete: `- [ ]` -> `- [x]`
3. Keep content PRODUCT-FOCUSED (no code details)

#### 4b: Sync Issue to Linear
Use Linear MCP to update the issue description:
```
linear_update_issue(
  issueId: "<issue-id>",
  description: "<issue file content - product sections only>"
)
```

Sync these sections: Summary, User Stories, Acceptance Criteria, Scope Clarification, Out of Scope

#### 4c: Update Spec File
1. Update `specs/{feature-name}.md` with technical details
2. Reference issue file: `See [{ISSUE_ID}-XXX](../issues/{ISSUE_ID}-XXX.md) for product requirements`

### Phase 5: Commit Changes

```bash
git status --short
# If uncommitted changes:
git add -A
git commit -m "chore: cleanup and consolidation for [feature-name]"
```

Do NOT push yet.

### Phase 6: Test Generation

Invoke `/forge:add-tests` to generate test coverage.

This will:
- Detect project test patterns
- Identify what needs tests (functions, APIs, pipelines)
- Generate unit + integration tests (no browser e2e)
- Run and verify all tests pass
- Commit the tests

### Phase 7: Code Review

Invoke `/code-review` (from the official Anthropic code-review plugin) to review the PR.

**Prerequisites**: Install the plugin first:
```
/plugin add anthropics/claude-plugins-official/plugins/code-review
```

The review will:
1. Run 5 parallel agents checking bugs, CLAUDE.md compliance, git history, etc.
2. Score each issue for confidence (0-100)
3. Only surface issues scoring 80+ to reduce false positives
4. Post findings as PR comment

If issues are found:
1. Fix the high-confidence issues
2. Re-run tests
3. Commit fixes:
   ```
   fix: address code review findings
   ```
4. Push and re-run `/code-review` to verify

### Phase 8: Final Push & PR Ready

1. Verify tests pass
2. Push to remote:
   ```bash
   git push origin <branch-name>
   ```

3. Find existing PR:
   ```bash
   gh pr list --head <branch-name> --base staging --json number,url,isDraft
   ```

4. **Convert PR from draft to ready for review**:
   ```bash
   gh pr ready <pr-number>
   ```

5. Update PR description with Linear issue table

6. Add PR link to Linear issue:
   ```
   linear_add_comment(issueId: "<id>", body: "PR: <url>")
   ```

7. Update Linear issue state to "In Review":
   ```
   linear_update_issue(issueId: "<id>", status: "In Review")
   ```

### Phase 9: Fix Review Findings

If `/code-review` found issues:
1. Read the PR comment with findings
2. Fix each high-confidence issue
3. Commit: `fix: address code review findings`
4. Push and re-run `/code-review`
5. Repeat until no issues found

## Quality Gates

Do NOT proceed to push if:
- Tests fail
- Code review has unresolved high-confidence issues
- Unspeced features remain unaddressed
- Spec file not aligned with implementation

## Output Summary

Report at completion of Phase 8 (before fix-pr):
- Files changed/removed
- Features verified against spec (both committed and uncommitted)
- Tests added
- PR converted from draft to ready
- Linear issue updated to "In Review"
- Linear/GitHub links created

Then `/forge:fix-pr` takes over for continuous CodeRabbit fixing.

## Error Handling

- **Linear MCP fails**: Report error, ask user to check `.mcp.json`
- **Tests fail**: Stop, report failures, await instruction
- **CodeRabbit fails**: Retry, if persistent report and await instruction
- **Git conflicts**: STOP and ask user to resolve manually
