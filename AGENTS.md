# Forge Plugin Development

## Commit & PR Rules

**NEVER credit Codex, Codex, or any AI tool in commits or PRs.** This means:
- No `Co-Authored-By: Codex` or similar trailers
- No mentions of "Codex", "Codex", "Anthropic", or "AI-generated" in commit messages
- No AI credits in PR descriptions or bodies
- Keep commits looking like normal developer commits

## Branch Naming

Branch names must follow the format: `{ISSUE-ID}-{description}` (e.g., `PROJ-468-feature-v02`).
Never prefix branches with `codex/`, `Codex/`, or any AI tool name. Just the ticket ID and a short description.

## When Making Changes

**ALWAYS do these steps when modifying forge:**

1. **Edit in ~/src/forge** - Never edit the plugin cache directly
2. **Bump version** in `.Codex-plugin/plugin.json` (every change, even small fixes)
3. **Commit and push** to GitHub

## Version Bumping

- Patch bump (1.16.0 → 1.16.1): Bug fixes, typos
- Minor bump (1.16.0 → 1.17.0): New commands or features

## Testing

After pushing, run `/plugin update` to install the new version.
