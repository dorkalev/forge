---
description: Fix SOC2 compliance failures from CI check
---
# /fix-compliance - Fix SOC2 Compliance Failures

Fixes common SOC2 CI failures: invalid tickets, ghost tickets (listed but no code), inherited merge tickets, missing tickets, unspecced changes.

```
/fix-compliance
/fix-compliance --tickets "PROJ-123,PROJ-456"
```

**Compliance model**: `Linear Tickets ←→ PR Description ←→ Code Changes`. Every change must trace to a ticket. File-level documentation is NOT required — ticket linkage is what matters.

### Phase 0: Read CI Check Failure (START HERE)

**CRITICAL: The PR comment only has summary-level info. The SPECIFIC unspecced files and recommendations are in the GitHub Actions run logs.** Always read BOTH.

**Step 1: Get the latest compliance comment and extract the run ID:**
```bash
# Get the latest SOC2 compliance comment (includes run ID in <sub> tag)
gh api repos/{owner}/{repo}/issues/{pr-number}/comments --jq '
  [.[] | select(.user.login == "github-actions[bot]" and (.body | contains("SOC2 Compliance")))] | last | .body'
```

Parse the comment:
- `## ✅ SOC2 Compliance: Passed` → nothing to fix, exit
- `## ❌ SOC2 Compliance: Failed` → continue
- Extract `run_id` from the `<sub>` tag at bottom: `[run {run_id}](...)`

**Step 2: Get the SPECIFIC failures from the run logs (this is where the real details are):**
```bash
# Extract the run_id from the comment's <sub> tag, then:
gh run view {run_id} --log 2>&1 | grep -E "##\[group\]|##\[error\]|  - " | grep -v "\[36;1m"
```

This gives you the structured output with:
- `##[error]` lines → the failure summary
- `##[group]Unspecced Changes (N)` → followed by `  - path/to/file.py: reason` lines
- `##[group]Issues (N)` → followed by `  - description` lines
- `##[group]Missing Documentation (N)` → followed by `  - TICKET-ID: reason` lines
- `Recommendations:` → followed by `  → suggestion` lines

**Step 3: Extract specific data:**
```bash
# Get unspecced files specifically
gh run view {run_id} --log 2>&1 | sed -n '/Unspecced Changes/,/endgroup/p' | grep "  - "

# Get missing documentation
gh run view {run_id} --log 2>&1 | sed -n '/Missing Documentation/,/endgroup/p' | grep "  - "

# Get recommendations
gh run view {run_id} --log 2>&1 | grep "  →"
```

### Phase 1: Analyze Current State
```bash
BRANCH=$(git branch --show-current)
gh pr view --json body,number,title -q '.'
```
Tickets from this branch's own commits: `git log staging..HEAD --no-merges --first-parent --format="%s%n%b" | grep -oE "[A-Z]+-[0-9]+" | sort -u`
Tickets inherited from merging staging (should NOT be in PR): compare `git log staging..HEAD --no-merges` vs `git log staging..HEAD --no-merges --first-parent` — any commits in the first but not the second came from staging merges. Extract their tickets to exclude.
**IMPORTANT:** `--first-parent` ensures only commits authored on this branch are included. Without it, merging origin/staging pulls in all staging commits and pollutes the ticket list.
Parse current PR Linear Tickets table.

### Phase 2: Identify Gaps

Cross-reference Phase 0 run log output with Phase 1 analysis:

**From run logs (primary source of truth):**
- `Unspecced Changes` items → these specific files need to be mentioned in the PR body's Technical Implementation section
- `Missing Documentation` items → need `issues/{TICKET}.md` files created
- `Issues` items → general compliance problems to address
- `Recommendations` → specific actions to take

**From git analysis:**
- Compare commit tickets vs PR table tickets
- Verify each ticket exists in Linear

### Phase 3: Resolve Each Gap

**For `unspecced_changes` (most common failure):**

The compliance checker uses Gemini AI to validate that every changed file in the diff is semantically covered by a ticket's description in the PR body. To fix:

1. Read each unspecced file from the run log output
2. Determine which ticket it belongs to (usually obvious from the file path/content)
3. Add a mention of this file in the PR body's Technical Implementation section under the appropriate ticket
4. Be explicit: `- \`path/to/file.py\`: Description of what changed and why`

Categorization:
- **Source files** → Add to Technical Implementation under the relevant ticket's subsection
- **Test files** (`test_*.py`, `conftest.py`) → Add to Testing & Verification section
- **Migration files** (`alembic/versions/*.py`) → Add to Technical Implementation under database changes
- **Config/infra files** → Add to Technical Implementation under infrastructure

**For `missing_documentation`:**
- If `TICKET-ID: no issues/ file found` → Create `issues/{TICKET-ID}.md` with product requirements
  - Fetch ticket from Linear (use MCP if available)
  - Write NON-TECHNICAL content: user stories, acceptance criteria, business logic
  - No implementation details in issues files
- If `TICKET-ID: no specs/ file found` → Create `specs/{feature-name}.md` with technical spec

**For ticket issues:**
- **Missing tickets**: Add to Linear Tickets table
- **Inherited (from merges)**: Remove from table
- **Invalid**: Check if typo, fix or remove
- **Ghost tickets**: Remove from table or explain in Audit Trail
- **No tickets at all**: AskUserQuestion — "Create new ticket" or "Link to existing"

### Phase 4: Build Updated PR Body

Construct with ALL of these sections:
1. **TL;DR** — 1-2 sentence summary
2. **Linear Tickets** table (`| Ticket | Title | Status |`)
3. **Product Requirements** — summary per ticket (from issues/ or Linear)
4. **Acceptance Criteria** table (`| Ticket | Criterion | Status |`)
5. **Technical Implementation** — organized by area, must mention ALL changed files explicitly
6. **Testing & Verification** — test files, CI results, manual testing
7. **Audit Trail** — timeline of changes

**The Technical Implementation section is what the compliance checker validates most strictly.** Every file in the git diff must be traceable to a ticket through this section. Group files by area but be explicit about each file path.

### Phase 5: Update PR and Create Missing Files

**Create any missing issues/specs files first, then commit and push:**
```bash
git add issues/ specs/
git commit -m "Add missing compliance documentation"
git push
```

**Then update the PR body:**
```bash
cat > /tmp/pr_body.md << 'EOF'
{constructed body}
EOF
gh pr edit {number} --body-file /tmp/pr_body.md
```

### Phase 6: Verify

Wait for CI to re-run after pushing. Check if the compliance check passes:
```bash
# Wait for check to complete (poll every 30s, max 5 min)
gh pr checks --watch --fail-fast
```

If it fails again, go back to Phase 0 and read the NEW compliance comment/logs.

## Error Handling
- **No PR found**: suggest `gh pr create`
- **Linear MCP not configured**: fall back to manual links
- **Complex conflicts**: ask user
- **No compliance comment yet**: wait for CI or use check run annotations
- **Gemini rate limited in CI**: the compliance report may be empty — wait and re-push to trigger re-run
