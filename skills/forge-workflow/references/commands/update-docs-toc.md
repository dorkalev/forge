---
description: Update CLAUDE.md with a table of contents linking all project documentation
---
# /update-docs-toc - Update Documentation Table of Contents

Scan the project for markdown documentation files and update CLAUDE.md with a `## Documentation` section. Also ensure `agents.md` is a symlink to `CLAUDE.md`.

## Process

### Step 1: Scan for documentation files

Search the project root for markdown files in these directories (if they exist):
- `docs/` — Domain docs and reference docs

Also include any top-level `.md` files that are NOT `CLAUDE.md`, `agents.md`, `README.md`, or `CHANGELOG.md`.

### Step 2: Build the TOC

Generate a `## Documentation` section with grouped links:

```markdown
## Documentation

### Domain Docs (current truth — read these first)
- [Product Overview](docs/product.md) — Brief title
- [Architecture](docs/architecture.md) — Brief title
- [Auth & Multi-Tenancy](docs/auth.md) — Brief title
- [Data Pipeline](docs/data-pipeline.md) — Brief title
- [Data Model](docs/data-model.md) — Brief title
- [Deployment](docs/deploy.md) — Brief title

### Reference Docs
- [Database Admin](docs/DATABASE_ADMIN.md) — Brief title
- [UUID Format Standard](docs/UUID_FORMAT_STANDARD.md) — Brief title

### Ticket Docs
Per-ticket product requirements in `issues/BOL-{ID}.md`, technical specs in `specs/bol-{id}-*.md`. Use `ls issues/ specs/` or glob to discover.
```

**Rules:**
- **Domain docs** are the 6 well-known files: `product.md`, `architecture.md`, `auth.md`, `data-pipeline.md`, `data-model.md`, `deploy.md`. List them first in a dedicated section if they exist.
- **Reference docs** are all other `docs/*.md` files. Extract the brief title from the first `#` heading, or fall back to the filename.
- **Ticket docs** are NOT individually listed. Just include a short note pointing to `issues/` and `specs/` directories.
- Sort entries alphabetically within each group
- Skip sections that would have zero entries
- Preserve ALL existing content in CLAUDE.md that is NOT between `## Documentation` markers
- If `## Documentation` section already exists, replace it entirely with the updated version
- Place the `## Documentation` section at the END of CLAUDE.md (before any trailing blank lines)

### Step 3: Ensure agents.md symlink

```bash
# Only if agents.md doesn't exist or isn't already a symlink to CLAUDE.md
if [ ! -L agents.md ] || [ "$(readlink agents.md)" != "CLAUDE.md" ]; then
    rm -f agents.md
    ln -s CLAUDE.md agents.md
fi
```

### Step 4: Report

Output what changed:
- Number of domain docs found
- Number of reference docs found
- Whether CLAUDE.md was updated
- Whether agents.md symlink was created/updated

## Notes

- This command is idempotent — running it multiple times produces the same result
- It is automatically invoked during `/finish` (Phase 4)
- The `## Documentation` section is machine-managed; manual edits to it will be overwritten
- Individual `issues/` and `specs/` files are NOT listed — they are discoverable via glob
