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
- `git reset --hard`
- `git clean -fd`
- `git restore --staged --worktree`

### Safe Alternatives:
- **Merge conflicts**: Ask user to resolve manually
- **Files need reverting**: Ask user to handle manually
- **Messy branch**: Work with what exists, commit incrementally
- **Need clean state**: Ask user to commit first

## Core Mission

Execute a comprehensive pre-push compliance workflow:
1. Code cleanliness and consolidation
2. Alignment between implementation and product specs
3. Test coverage
4. Automated code review compliance
5. Full Linear/GitHub traceability for SOC2 compliance
6. Bidirectional sync between `issues/` files and Linear tickets

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
4. Analyze ALL code changes since `staging`:
   ```bash
   git log staging..HEAD --oneline
   git diff staging...HEAD --stat
   ```

### Phase 2: Cleanup & Consolidation

1. Remove unnecessary files (temp, debug, duplicates)
2. Consolidate code where safe
3. Run linting/formatting
4. Check for files that should be gitignored

### Phase 3: Spec Alignment Verification

1. Extract implemented features from `git diff staging...HEAD`
2. Compare against `issues/` file
3. Categorize: **Speced** vs **Unspeced**

For UNSPECED features, ask user:
```
UNSPECED FEATURE DETECTED:
Feature: [description]

Options:
1. Add to current spec - Update the Linear ticket
2. Create new ticket - Create separate Linear ticket
3. Remove feature - Delete the unspeced code
```

Execute choice using Linear MCP:
- **Option 1**: `linear_update_issue(issueId, description: "<updated>")`
- **Option 2**: `linear_create_issue(...)` then `linear_add_comment(issueId, "PR: <url>")`
- **Option 3**: Remove the code

### Phase 4: Issue & Spec File Management

#### 4a: Update Issue File
1. Update `issues/{TICKET}.md` with scope changes
2. Mark acceptance criteria complete: `- [ ]` -> `- [x]`
3. Keep content PRODUCT-FOCUSED (no code details)

#### 4b: Sync Issue to Linear
Use Linear MCP to update the ticket description:
```
linear_update_issue(
  issueId: "<ticket-id>",
  description: "<issue file content - product sections only>"
)
```

Sync these sections: Summary, User Stories, Acceptance Criteria, Scope Clarification, Out of Scope

#### 4c: Update Spec File
1. Update `specs/{feature-name}.md` with technical details
2. Reference issue file: `See [{TICKET}-XXX](../issues/{TICKET}-XXX.md) for product requirements`

### Phase 5: Commit Changes

```bash
git status --short
# If uncommitted changes:
git add -A
git commit -m "chore: cleanup and consolidation for [feature-name]"
```

Do NOT push yet.

### Phase 6: Test Generation

1. Generate tests for core functionality
2. Follow project testing conventions
3. Run tests and ensure they pass
4. Commit tests:
   ```
   test: add coverage for [feature-name]
   ```

### Phase 7: CodeRabbit Review

1. Run `scripts/coderabbit-review.sh`
2. If CLI fails, trigger via PR comment: `@coderabbitai review`
3. Fix Critical/High issues, document skipped Low issues
4. Re-run tests after fixes
5. Commit fixes:
   ```
   fix: address CodeRabbit review findings
   ```

### Phase 8: Final Push & PR Linking

1. Verify tests pass
2. Push to remote:
   ```bash
   git push origin <branch-name>
   ```

3. Find existing PR:
   ```bash
   gh pr list --head <branch-name> --base staging --json number,url
   ```

4. Update PR description with Linear ticket table

5. Add PR link to Linear ticket:
   ```
   linear_add_comment(issueId: "<id>", body: "PR: <url>")
   ```

6. Update Linear ticket state to "In Review":
   ```
   linear_update_issue(issueId: "<id>", status: "In Review")
   ```

## Quality Gates

Do NOT proceed to push if:
- Tests fail
- CodeRabbit has unresolved critical issues
- Unspeced features remain unaddressed
- Spec file not aligned with implementation

## Output Summary

Report at completion:
- Files changed/removed
- Features verified against spec
- Tests added
- CodeRabbit issues resolved
- Linear/GitHub links created

## Error Handling

- **Linear MCP fails**: Report error, ask user to check `.mcp.json`
- **Tests fail**: Stop, report failures, await instruction
- **CodeRabbit fails**: Retry, if persistent report and await instruction
- **Git conflicts**: STOP and ask user to resolve manually
