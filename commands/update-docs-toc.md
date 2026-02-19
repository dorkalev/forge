---
description: Update CLAUDE.md with a table of contents linking all project documentation
---
# /update-docs-toc - Update Documentation Table of Contents

Scan the project for markdown documentation files and update CLAUDE.md with a `## Documentation` section that links to all of them. Also ensure `agents.md` is a symlink to `CLAUDE.md`.

## Process

### Step 1: Scan for documentation files

Search the project root for markdown files in these directories (if they exist):
- `issues/` — Product requirements (from Linear)
- `specs/` — Technical specifications
- `docs/` — General documentation

Also include any top-level `.md` files that are NOT `CLAUDE.md`, `agents.md`, `README.md`, or `CHANGELOG.md`.

### Step 2: Build the TOC

Generate a `## Documentation` section with grouped links:

```markdown
## Documentation

### Issues
- [PROJ-123](issues/PROJ-123.md) — Brief title from first heading or filename
- [PROJ-456](issues/PROJ-456.md) — Brief title

### Specs
- [feature-module](specs/feature-module.md) — Brief title
- [proj-477](specs/proj-477.md) — Brief title

### Docs
- [UUID Format Standard](docs/UUID_FORMAT_STANDARD.md) — Brief title
- [Database Admin](docs/DATABASE_ADMIN.md) — Brief title
```

**Rules:**
- Extract the brief title from the first `#` heading in each file, or fall back to the filename
- Sort entries alphabetically within each group
- Skip empty directories
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
- Number of docs found per category
- Whether CLAUDE.md was updated
- Whether agents.md symlink was created/updated

## Notes

- This command is idempotent — running it multiple times produces the same result
- It is automatically invoked during `/finish` (Phase 4)
- The `## Documentation` section is machine-managed; manual edits to it will be overwritten
