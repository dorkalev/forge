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
| `/forge:issues` | Browse your assigned Linear issues or create a new one |
| `/forge:new-issue <desc>` | Create a new Linear ticket and set up full dev environment |
| `/forge:ticketify` | Turn your planning discussion into a Linear ticket |

### Development

| Command | Description |
|---------|-------------|
| `/forge:ticket <id>` | Fetch a Linear ticket, save requirements, create technical plan |
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

## License

MIT
