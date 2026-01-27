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
  { content: "Phase 2.5: Code Simplification", status: "pending" },
  { content: "Phase 3: Spec Alignment Verification", status: "pending" },
  { content: "Phase 4: Issue & Spec File Management", status: "pending" },
  { content: "Phase 5: Commit Changes", status: "pending" },
  { content: "Phase 5.5: Sync with Staging", status: "pending" },
  { content: "Phase 6: Test Generation", status: "pending" },
  { content: "Phase 7: Push & Code Review Loop", status: "pending" },
  { content: "Phase 8: PR Ready & Linear Sync", status: "pending" },
  { content: "Phase 8.5: Build PR Compliance Document", status: "pending" },
  { content: "Phase 9: CodeRabbit Loop", status: "pending" }
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
7. **PR as self-contained SOC2 audit record** - Full product spec, technical highlights, verification evidence, all in the PR body

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

### Phase 2.5: Code Simplification

**Requires**: `code-simplifier` plugin from Anthropic

1. Check if `code-simplifier` is installed:
   ```bash
   claude plugin list 2>/dev/null | grep -q "code-simplifier@claude-plugins-official"
   ```

   If NOT installed, prompt user:
   ```
   Code simplification requires the code-simplifier plugin.
   Install it with: /plugin install code-simplifier

   Options:
   1. Install now and continue
   2. Skip code simplification
   ```

2. Identify source files changed since `staging`:
   ```bash
   git diff staging...HEAD --name-only -- '*.py' '*.ts' '*.tsx' '*.js' '*.jsx'
   git diff --name-only -- '*.py' '*.ts' '*.tsx' '*.js' '*.jsx'
   ```

3. If source files changed, invoke the `code-simplifier` agent via Task tool:
   - Pass the list of changed files
   - Agent will simplify code for clarity and maintainability
   - Preserves functionality, applies project standards

4. Stage any simplification changes

**Skip this phase if**:
- No source code files were modified (only config/docs)
- User chose to skip in step 1

### Phase 3: Spec Alignment Verification (CRITICAL)

**Goal**: Ensure complete alignment between 4 sources of truth:
1. **Linear ticket** - The authoritative product spec
2. **`issues/` file** - Local copy of product requirements
3. **`specs/` file** - Technical implementation plan
4. **Actual diff** - What was actually implemented

#### Step 3.1: Gather All Sources

```bash
# Get actual implementation diff
git diff staging...HEAD   # committed
git diff                  # uncommitted (unstaged)
git diff --cached         # uncommitted (staged)
```

Read the issue file from `issues/{ISSUE_ID}.md`.
Read the spec file from `specs/{feature-name}.md`.
Fetch Linear ticket content using Linear MCP: `linear_get_issue(id: "<ticket-id>")`

#### Step 3.2: Cross-Reference Analysis

Create a misalignment report by comparing all 4 sources:

```
## Alignment Analysis

### What Linear Says (Product Spec)
- Requirement A: [from Linear description]
- Requirement B: [from Linear description]
- Acceptance Criteria: [list from Linear]

### What issues/ File Says
- [compare with Linear - note any drift]

### What specs/ File Says
- Technical approach: [summary]
- Components touched: [list]

### What Was Actually Implemented (Diff)
- Files changed: [list]
- Features added: [list]
- Features modified: [list]

### MISALIGNMENTS FOUND:

| Type | Description | Source A | Source B | Action Needed |
|------|-------------|----------|----------|---------------|
| UNSPECED | Feature X implemented but not in any spec | Diff | - | Add to spec or remove |
| DRIFT | Requirement Y in Linear but not in issues/ | Linear | issues/ | Sync files |
| INCOMPLETE | Acceptance criterion Z not implemented | Linear | Diff | Implement or descope |
| SCOPE_CREEP | Feature W added beyond requirements | Diff | Linear | Document or remove |
```

#### Step 3.3: Resolve Each Misalignment

For each misalignment, ask user to choose resolution:

**UNSPECED (implemented but not documented):**
```
UNSPECED FEATURE: [description]
Found in: [files]

Options:
1. Add to current Linear issue - Update product spec
2. Create new Linear issue - Separate ticket for SOC2 traceability
3. Remove feature - Delete the unspeced code
```

**DRIFT (Linear ≠ issues/ file):**
```
SPEC DRIFT DETECTED:
Linear says: [content]
issues/ says: [content]

Options:
1. Sync issues/ FROM Linear (Linear is authoritative)
2. Update Linear FROM issues/ (local changes are intentional)
```

**INCOMPLETE (spec'd but not implemented):**
```
INCOMPLETE IMPLEMENTATION:
Requirement: [from Linear]
Status: Not found in diff

Options:
1. Implement now - Add the missing functionality
2. Descope - Remove from Linear issue (with comment explaining why)
3. Defer - Create follow-up issue
```

**SCOPE_CREEP (implemented beyond spec):**
```
SCOPE CREEP DETECTED:
Feature: [description]
Not in: Linear, issues/, or specs/

Options:
1. Expand scope - Add to Linear issue
2. New issue - Create separate ticket
3. Remove - Delete the extra code
```

Execute choices using Linear MCP:
- **Update issue**: `linear_update_issue(issueId, description: "<updated>")`
- **Create issue**: `linear_create_issue(...)` then `linear_create_comment(issueId, "Related: <new-issue-url>")`
- **Add comment**: `linear_create_comment(issueId, body: "<explanation>")`

#### Step 3.4: Final Alignment Check

After resolving all misalignments, verify:
- [ ] Every change in diff maps to a Linear requirement
- [ ] issues/ file matches Linear ticket
- [ ] specs/ file describes the technical approach for all features
- [ ] No undocumented code remains

**Do NOT proceed to Phase 4 until alignment is confirmed.**

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

### Phase 5.5: Sync with Staging

**Goal**: Merge latest staging into branch AFTER local work is committed (safe).

```bash
git fetch origin staging
git merge origin/staging --no-edit
```

#### If merge conflicts occur:

1. List conflicted files:
   ```bash
   git diff --name-only --diff-filter=U
   ```

2. **Attempt to resolve each conflict automatically**:
   - Read the conflicted file
   - Analyze conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
   - Understand both sides:
     - **OURS (HEAD)**: Your changes from this branch
     - **THEIRS (origin/staging)**: Changes merged from staging
   - Apply intelligent resolution:
     - If both sides add different things: keep both
     - If both modify same line: prefer OURS unless THEIRS is clearly a bug fix
     - If THEIRS deletes something OURS modified: keep OURS
   - Remove conflict markers and save

3. After resolving all files:
   ```bash
   git add -A
   git commit -m "merge: sync with staging"
   ```

4. **If a conflict is too complex** (e.g., large refactor on both sides):
   - STOP and ask user to resolve manually
   - Show the specific file and conflict
   - Wait for user to confirm resolution before continuing

#### If merge is clean:

Continue to Phase 6.

### Phase 6: Test Generation

Invoke `/forge:add-tests` to generate test coverage.

This will:
- Detect project test patterns
- Identify what needs tests (functions, APIs, pipelines)
- Generate unit + integration tests (no browser e2e)
- Run and verify all tests pass
- Commit the tests

### Phase 7: Push & Code Review Loop

**Prerequisites**: Install the Anthropic code-review plugin:
```
/plugin add anthropics/claude-plugins-official/plugins/code-review
```

1. Push to remote (PR must exist for /code-review):
   ```bash
   git push origin <branch-name>
   ```

2. Run `/code-review` (Anthropic plugin only)
   - 5 parallel agents check bugs, CLAUDE.md compliance, git history
   - Only issues scoring 80+ confidence are surfaced

3. If issues found:
   - Fix each issue
   - Re-run tests
   - Commit: `fix: address code review findings`
   - Push
   - Re-run `/code-review`

4. **Repeat until `/code-review` reports "No issues found"**

### Phase 8: PR Ready & Linear Sync

1. Find existing PR:
   ```bash
   gh pr list --head <branch-name> --base staging --json number,url,isDraft
   ```

2. **Convert PR from draft to ready for review**:
   ```bash
   gh pr ready <pr-number>
   ```

3. Update PR description with Linear issue table

4. Add PR link to Linear issue:
   ```
   linear_create_comment(issueId: "<id>", body: "PR: <url>")
   ```

5. Update Linear issue state to "In Review":
   ```
   linear_update_issue(issueId: "<id>", status: "In Review")
   ```

### Phase 8.5: Build Comprehensive PR Document (CRITICAL for SOC2)

Invoke `/forge:verify-pr --fix` to build the PR into a **self-contained SOC2 audit record**.

This builds a comprehensive PR body containing:
- **TL;DR**: One-sentence summary of the change
- **Linear Tickets**: Table with all tickets, titles, and status
- **Product Requirements**: Full content from `issues/` files (Summary, Acceptance Criteria, Out of Scope)
- **Technical Implementation**: Condensed from `specs/` (Architecture, Key Changes, Notable Decisions)
- **Testing & Verification**: Table showing test status and manual verification
- **Audit Trail**: Cross-links and scope change notes

The workflow will:
1. Gather sources from commits, issues/, specs/, and Linear
2. Prompt for verification of each acceptance criterion
3. Detect unspecced changes and resolve them
4. Build and update the PR body
5. Validate all ticket links (404 check)
6. Add cross-links to Linear issues

**An auditor should be able to understand the entire change from the PR alone.**

**Do NOT proceed to Phase 9 until `/forge:verify-pr` passes.**

### Phase 9: CodeRabbit Loop

After PR is ready, CodeRabbit (GitHub bot) will review. Loop until clean:

1. **Wait 3 minutes** for CodeRabbit to review:
   ```bash
   sleep 180
   ```

2. Fetch CodeRabbit comments:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{pr-number}/comments
   ```
   Filter for `coderabbitai[bot]}`.

3. Check for Major/Critical issues:
   - **Critical**: `_Critical_` - MUST fix
   - **Major**: `_Major_` - MUST fix
   - **Minor/Trivial**: skip

4. If Major/Critical found:
   - Fix each issue
   - Commit: `fix: address CodeRabbit findings`
   - Push
   - Reply to comment: `Fixed in commit {hash}`
   - Go back to step 1 (wait 3 min)

5. **Repeat until no Major/Critical issues remain**

## Quality Gates

Do NOT proceed to push if:
- Tests fail
- Code review has unresolved high-confidence issues
- Unspeced features remain unaddressed
- Spec file not aligned with implementation
- PR missing required sections (TL;DR, Product Requirements, Technical Implementation)
- Acceptance criteria not verified
- Unspecced changes detected without resolution

## Output Summary

Report at completion:
- Files changed/removed
- Features verified against spec
- Tests added
- `/code-review` passed (no issues)
- PR converted from draft to ready
- Linear issue updated to "In Review"
- **PR compliance document built** (Product Requirements, Technical Implementation, Acceptance Criteria verified, cross-links created)
- CodeRabbit passed (no Major/Critical)

## Error Handling

- **Linear MCP fails**: Report error, ask user to check `.mcp.json`
- **Tests fail**: Stop, report failures, await instruction
- **CodeRabbit fails**: Retry, if persistent report and await instruction
- **Git conflicts**: STOP and ask user to resolve manually
