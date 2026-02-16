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

Read the SOC2 compliance check output to understand exactly what failed:

```bash
# Find the latest SOC2 compliance comment from github-actions[bot]
gh api repos/{owner}/{repo}/issues/{pr-number}/comments --jq '
  [.[] | select(.user.login == "github-actions[bot]" and (.body | contains("SOC2 Compliance")))] | last | .body'
```

Parse the comment for the structured failure report:
- `## ✅ SOC2 Compliance: Passed` → nothing to fix, exit
- `## ❌ SOC2 Compliance: Failed` → parse "### What Failed" section

Extract each failure category from the comment body:
- **`unspecced_changes`** — Files in the diff not covered by any ticket's Key Changes table or description
- **`inherited_tickets`** — Tickets from merge commits listed in PR but not authored on this branch
- **`invalid_tickets`** — Tickets listed in PR that don't exist in Linear
- **`unimplemented_tickets`** / **`ghost tickets`** — Tickets listed in PR with no code changes
- **`missing_ticket`** — Code changes with no ticket reference at all

If no compliance comment exists yet, fall back to checking the check run annotations:
```bash
# Get latest check run for the compliance job
gh api repos/{owner}/{repo}/commits/$(git rev-parse HEAD)/check-runs --jq '
  .check_runs[] | select(.name | contains("tickets-and-specs")) |
  {conclusion, annotations_url}'

# Get annotations for failure details
gh api {annotations_url} --jq '.[] | .message'
```

Also extract the full unspecced file list from the check run log if available:
```bash
gh run view {run_id} --log 2>&1 | grep -A 50 "Unspecced Changes"
```

### Phase 1: Analyze Current State
```bash
BRANCH=$(git branch --show-current)
gh pr view --json body,number,title -q '.'
```
Tickets from this branch's own commits: `git log staging..HEAD --no-merges --first-parent --format="%s%n%b" | grep -oE "[A-Z]+-[0-9]+" | sort -u`
Tickets inherited from merging staging (should NOT be in PR): compare `git log staging..HEAD --no-merges` vs `git log staging..HEAD --no-merges --first-parent` — any commits in the first but not the second came from staging merges. Extract their tickets to exclude.
**IMPORTANT:** `--first-parent` ensures only commits authored on this branch are included. Without it, merging origin/staging pulls in all staging commits (e.g., BOL-449, BOL-452) and pollutes the ticket list.
Parse current PR Linear Tickets table.

### Phase 2: Identify Gaps

Cross-reference Phase 0 CI output with Phase 1 analysis:

**From CI check comment:**
- If `unspecced_changes` listed → these files need to be added to Key Changes table or documented in PR body
- If `inherited_tickets` listed → these tickets need to be removed from Linear Tickets table
- If `invalid_tickets` listed → verify in Linear, fix typos or remove
- If `ghost tickets` / `unimplemented_tickets` → remove from PR or implement

**From git analysis:**
- Compare commit tickets vs PR table tickets
- Verify each ticket exists in Linear

### Phase 3: Resolve Each Gap

**For `unspecced_changes` (most common failure):**
- Read the list of unspecced files from CI output
- Categorize them:
  - **Test files** (`test_*.py`, `conftest.py`) → Add to "Test files updated" section, not Key Changes
  - **Migration files** (`alembic/versions/*.py`) → Add to Key Changes under appropriate area (e.g., "Migration chain")
  - **Config/infra files** → Add to Key Changes or Audit Trail with explanation
- Update the PR body's Key Changes table to include these files with their ticket reference
- The CI checker uses Gemini to verify coverage — being explicit in the PR body about what each file does helps it pass

**For ticket issues:**
- **Missing tickets**: Add to Linear Tickets table
- **Inherited (from merges)**: Remove from table
- **Invalid**: Check if typo, fix or remove
- **Ghost tickets**: Remove from table or explain in Audit Trail
- **No tickets at all**: AskUserQuestion — "Create new ticket" or "Link to existing"

### Phase 4: Build Updated PR Body
Construct with: TL;DR, Linear Tickets table (`| Ticket | Title | Status |`), Product Requirements (from issues/ or Linear), Acceptance Criteria table, Technical Implementation (Key Changes table must cover ALL changed files), Testing & Verification, Audit Trail.

**Key Changes table must be comprehensive** — the CI check validates that files in the diff appear in this table. Group related files under area headings rather than listing each file individually. Test files should be in a separate "Testing & Verification" section, not Key Changes.

### Phase 5: Update PR
```bash
cat > /tmp/pr_body.md << 'EOF'
{constructed body}
EOF
gh pr edit {number} --body-file /tmp/pr_body.md
```

### Phase 6: Verify
Pass when: every PR ticket exists in Linear, no orphan tickets, no merge commit tickets, all changed files referenced in PR body.

Wait for CI to re-run after pushing the PR body update. Check if the compliance check passes:
```bash
# Wait for check to complete (poll every 30s, max 5 min)
gh pr checks --watch --fail-fast
```

## Error Handling
- **No PR found**: suggest `gh pr create` | **Linear MCP not configured**: fall back to manual links | **Complex conflicts**: ask user | **No compliance comment yet**: wait for CI or use check run annotations
