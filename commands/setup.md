---
description: Install recommended development tools (iTerm, tmux, Marta, Meld, Linear, Slack)
---

# /setup - Install Development Tools

You are an automation assistant that helps developers set up their development environment.

## Your Mission

When the user runs `/setup`, install the recommended tools for the forge workflow.

### Step 1: Check Prerequisites

Verify Homebrew is installed:

```bash
which brew
```

If not installed, show:
```
Homebrew is required. Install it first:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

Then run /forge:setup again.
```
And exit.

### Step 2: Show Installation Plan

Display what will be installed:

```
## Forge Development Tools Setup

The following tools will be installed:

| Tool | Description | Method |
|------|-------------|--------|
| iTerm2 | Terminal emulator with tmux integration | brew install --cask iterm2 |
| tmux | Terminal multiplexer for session management | brew install tmux |
| Marta | Dual-pane file manager | brew install --cask marta |
| Meld | Visual diff and merge tool | brew install --cask meld |
| Linear | Issue tracking app | brew install --cask linear-linear |
| Slack | Team communication | brew install --cask slack |

**Also recommended (not auto-installed):**
- **Warp** - AI-powered terminal with modern UX: `brew install --cask warp`
```

### Step 3: Confirm Installation

Use AskUserQuestion:
- Header: "Install"
- Question: "Install all recommended tools?"
- Options:
  - "Install all" - Install everything listed
  - "Select tools" - Let me choose which ones to install
  - "Cancel" - Don't install anything

If "Select tools", use another AskUserQuestion with multiSelect: true:
- Header: "Tools"
- Question: "Which tools do you want to install?"
- Options: iTerm2, tmux, Marta, Meld (limit of 4, then ask again for Linear, Slack)

### Step 4: Install Tools

Run the installations for selected tools:

```bash
# CLI tools
brew install tmux

# GUI apps (casks)
brew install --cask iterm2
brew install --cask marta
brew install --cask meld
brew install --cask linear-linear
brew install --cask slack
```

Run each installation and report progress:

```
Installing iTerm2... done
Installing tmux... done
Installing Marta... done
Installing Meld... done
Installing Linear... done
Installing Slack... done
```

### Step 5: Post-Install Configuration

After installation, suggest optional configuration:

```
## Setup Complete

All tools installed successfully.

**Optional next steps:**
- Set iTerm2 as default terminal
- Configure Marta as default file manager
- Sign in to Linear and Slack
- Consider installing Warp for an AI-enhanced terminal: `brew install --cask warp`

Run `/forge:start` to begin working on an issue.
```

## Error Handling

- If a tool is already installed: Skip it and note "already installed"
- If brew install fails: Show error and continue with remaining tools
- If user doesn't have admin rights: Suggest running with sudo or contacting IT
