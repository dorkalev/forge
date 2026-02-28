---
description: Review and update domain-level docs based on code changes
---
# /update-domain-docs - Keep Domain Docs Current

Review domain docs in `docs/` against code changes on the current branch and update any that have become stale. Domain docs represent **current truth** — they describe how the system works today.

## When This Runs

- Automatically during `/finish` (Phase 4, after spec alignment)
- Manually via `/forge:update-domain-docs`

## Process

### Step 1: Identify affected domain docs

Map changed files to domain docs:

```bash
git diff staging...HEAD --stat --name-only
```

| Changed files match | Domain doc |
|-------------------|------------|
| `web/auth/*`, `web/backoffice/dependencies.py`, `web/backoffice/middleware.py` | `docs/auth.md` |
| `algo/*`, `services/upload/local_pipeline.py`, `packages/data-access/*` | `docs/data-pipeline.md` |
| `web/backoffice/models.py`, `web/alembic/*` | `docs/data-model.md` |
| `infra/*`, `.github/workflows/*`, `**/Dockerfile`, `**/deploy*` | `docs/deploy.md` |
| Service entrypoints, Dockerfiles, terraform, `packages/*` | `docs/architecture.md` |
| `web/backoffice/routes.py`, `web/vlad/*`, `algo/analyst_agent/*`, UI components | `docs/product.md` |

If no domain docs are affected, report "No domain docs need updating" and exit.

### Step 2: Review each affected doc

For each affected domain doc:

1. Read the current doc content
2. Read the relevant diffs (`git diff staging...HEAD -- <affected-files>`)
3. Determine if the doc needs updating:
   - **New features/services added** → add to doc
   - **Existing behavior changed** → update doc
   - **Code removed** → remove from doc
   - **Trivial changes** (formatting, comments, tests) → skip

### Step 3: Update docs in-place

Edit each stale doc to reflect current truth. Rules:
- Keep the same structure and format
- Stay within 1-2 pages
- Focus on current state, not change history
- Update file path references if files moved
- Add cross-references to new ticket specs where relevant

### Step 4: Report

Output:
- Which domain docs were checked
- Which were updated (and brief summary of changes)
- Which were already current (no changes needed)

## Notes

- This command is idempotent — running it multiple times produces the same result
- Domain docs should never contain ticket-specific history — that belongs in `specs/`
- If a domain doc doesn't exist yet, skip it (creation is a separate task)
- If changes are too extensive to summarize in-place, flag for user review
