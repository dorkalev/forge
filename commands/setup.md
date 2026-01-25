---
description: Install recommended development tools and Claude Code plugins
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

### Step 5: Configure tmux

Install the optimized tmux configuration for Claude/TUI apps:

```bash
cat > ~/.tmux.conf << 'EOF'
# ==========================================
# FIX CLAUDE / TUI STICKING ISSUES
# ==========================================

# 1. Enable Mouse Support
# This allows you to scroll the Claude output with your touchpad,
# which often un-sticks the rendering if it freezes.
set -g mouse on

# 2. Fix Colors & Rendering
# 'tmux-256color' tells applications (like Claude) that this is a
# high-performance terminal, preventing artifacts.
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# 3. Increase History
# Prevents the terminal from freaking out when Claude generates long code blocks.
set -g history-limit 50000

# 4. Remove Input Delay (The "Lag" Fix)
# By default, tmux waits for escape sequences. This makes TUI apps feel sticky.
set -s escape-time 0

# 5. Enable Focus Events
# Helps Claude understand when you click into the pane so it can redraw.
set -g focus-events on

# ==========================================
# PREVENT ACCIDENTAL FREEZES (Flow Control)
# ==========================================

# Unbind keys that pause the terminal output
unbind C-s
unbind C-q

# ==========================================
# OPTIONAL: QUALITY OF LIFE
# ==========================================

# Reload this config with 'Prefix + r'
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Split panes with | and - (easier to remember)
bind | split-window -h
bind - split-window -v
EOF
```

If `~/.tmux.conf` already exists, ask before overwriting:
- Header: "Config"
- Question: "~/.tmux.conf already exists. Replace with Forge-optimized config?"
- Options:
  - "Replace" - Overwrite with the new config
  - "Skip" - Keep existing config

Report: `Configured ~/.tmux.conf for Claude/TUI compatibility`

### Step 6: Install Claude Code Plugins

These plugins enhance `/forge:finish`:

```
## Claude Code Plugins

The following plugins are recommended for the full forge workflow:

| Plugin | Purpose | Used In |
|--------|---------|---------|
| code-simplifier | Simplifies code for clarity | /forge:finish Phase 2.5 |
| code-review | Multi-agent code review | /forge:finish Phase 7 |
```

Use AskUserQuestion:
- Header: "Plugins"
- Question: "Install recommended Claude Code plugins?"
- Options:
  - "Install both (Recommended)" - Install code-simplifier and code-review
  - "Skip" - Don't install plugins now

If installing, run:
```bash
claude plugin install code-simplifier
claude plugin install code-review
```

Note: User will need to restart Claude Code after plugin installation.

### Step 7: Post-Install Summary

After installation, show summary:

```
## Setup Complete

All tools installed successfully.

**Configured:**
- ~/.tmux.conf optimized for Claude Code (mouse, colors, no input lag)

**Plugins installed:**
- code-simplifier (code clarity)
- code-review (multi-agent review)

**Optional next steps:**
- Set iTerm2 as default terminal
- Configure Marta as default file manager
- Sign in to Linear and Slack
- Consider installing Warp for an AI-enhanced terminal: `brew install --cask warp`

**Restart Claude Code** to load new plugins, then run `/forge:start` to begin working on an issue.
```

## Error Handling

- If a tool is already installed: Skip it and note "already installed"
- If brew install fails: Show error and continue with remaining tools
- If user doesn't have admin rights: Suggest running with sudo or contacting IT
