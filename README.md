# Forge

A Claude Code plugin with commands for Linear-integrated development workflows.

## Installation

```bash
/plugin install forge@dorkalev/forge
```

## Prerequisites

These commands require:
- **Linear MCP server** configured in `.mcp.json`
- **gh CLI** authenticated (`gh auth login`) - used for all GitHub operations

### Optional Plugins

For full `/forge:finish` functionality, install these Anthropic plugins:

```bash
/plugin install code-simplifier   # Code simplification (Phase 2.5)
/plugin install code-review       # Code review (Phase 7)
```

Example `.mcp.json`:
```json
{
  "mcpServers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.linear.app/sse"]
    }
  }
}
```

## Available Commands

### Planning

| Command | Description |
|---------|-------------|
| `/forge:start` | Browse your assigned Linear issues or create a new one |
| `/forge:new-issue <desc>` | Create a new Linear issue and set up full dev environment |
| `/forge:capture` | Turn your planning discussion into a Linear issue |

### Development

| Command | Description |
|---------|-------------|
| `/forge:load <id>` | Fetch a Linear issue, save requirements, create technical plan |
| `/forge:worktree` | Create a git worktree for an existing branch |
| `/forge:pr` | Open the GitHub PR page for the current branch in browser |

### Review

| Command | Description |
|---------|-------------|
| `/forge:audit` | Check SOC2 compliance status (read-only) |
| `/forge:finish` | Run pre-push compliance workflow (cleanup, tests, review) |
| `/forge:fix-pr` | Auto-fix CodeRabbit review findings in a loop |

### Completion

| Command | Description |
|---------|-------------|
| `/forge:cleanup` | Clean up a worktree after its PR is merged |

### Help

| Command | Description |
|---------|-------------|
| `/forge:help` | List all available commands |

## Configuration

Create a `.forge` file in your project root with worktree configuration:

```bash
WORKTREE_REPO_PATH=/path/to/main/repo
WORKTREE_BASE_PATH=/path/to/worktrees
```

## File Structure

These commands expect the following project structure:

```
your-project/
├── .forge              # Worktree configuration
├── .mcp.json           # MCP server configuration
├── issues/             # Product requirements (WHAT & WHY)
│   └── PROJ-123.md
└── specs/              # Technical specifications (HOW)
    └── proj-123-feature.md
```


## Codex Support

Forge now includes a Codex skill package at `skills/forge-workflow` so the same workflow can be used in Codex.

### Install Locally

```bash
mkdir -p ~/.codex/skills
cp -R skills/forge-workflow ~/.codex/skills/
```

Restart Codex after installation.

### Install via Skill Installer (after pushing repo)

```bash
python ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py   --repo dorkalev/forge   --path skills/forge-workflow
```

### Usage

Ask Codex to use `forge-workflow` and then request a Forge action, for example:
- "Use forge-workflow and run start for BOL-420"
- "Use forge-workflow and run finish"
- "Use forge-workflow and run fix-pr"

## License

MIT
