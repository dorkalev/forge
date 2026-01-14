# Forge Skills

A collection of Claude Code skills for Linear-integrated development workflows.

## Installation

```bash
# Add this marketplace to Claude Code
/plugin marketplace add dorkalev/forge

# Install all skills
/plugin install forge@dorkalev/forge
```

Or install individual skills:
```bash
/plugin install ticket@dorkalev/forge
/plugin install issues@dorkalev/forge
/plugin install finish@dorkalev/forge
```

## Prerequisites

These skills require:
- **Linear MCP server** configured in `.mcp.json`
- **GitHub MCP server** (for PR-related skills)
- **gh CLI** authenticated (`gh auth login`)

Example `.mcp.json`:
```json
{
  "mcpServers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.linear.app/sse"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://api.githubcopilot.com/mcp/"]
    }
  }
}
```

## Available Skills

### Planning

| Skill | Description |
|-------|-------------|
| `/issues` | Browse your assigned Linear issues or create a new one |
| `/new-issue <desc>` | Create a new Linear ticket and set up full dev environment |
| `/ticketify` | Turn your planning discussion into a Linear ticket |

### Development

| Skill | Description |
|-------|-------------|
| `/ticket <id>` | Fetch a Linear ticket, save requirements, create technical plan |
| `/worktree` | Create a git worktree for an existing branch |
| `/pr` | Open the GitHub PR page for the current branch in browser |

### Review

| Skill | Description |
|-------|-------------|
| `/audit` | Check SOC2 compliance status (read-only) |
| `/finish` | Run pre-push compliance workflow (cleanup, tests, review) |
| `/fix-pr` | Auto-fix CodeRabbit review findings in a loop |

### Completion

| Skill | Description |
|-------|-------------|
| `/cleanup` | Clean up a worktree after its PR is merged |

### Help

| Skill | Description |
|-------|-------------|
| `/forge` | List all available skills |

## Configuration

Create a `.forge` file in your project root with worktree configuration:

```bash
WORKTREE_REPO_PATH=/path/to/main/repo
WORKTREE_BASE_PATH=/path/to/worktrees
```

## File Structure

These skills expect the following project structure:

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
