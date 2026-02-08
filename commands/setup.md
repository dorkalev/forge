---
description: Install recommended development tools and Claude Code plugins
---
# /setup - Install Development Tools

### Step 1: Check Prerequisites
```bash
which brew
```
If not installed: `Install Homebrew first, then run /forge:setup again.`

### Step 2: Show Installation Plan

| Tool | Description | Method |
|------|-------------|--------|
| iTerm2 | Terminal with tmux integration | `brew install --cask iterm2` |
| tmux | Session management | `brew install tmux` |
| Marta | Dual-pane file manager | `brew install --cask marta` |
| Meld | Visual diff/merge | `brew install --cask meld` |
| Linear | Issue tracking | `brew install --cask linear-linear` |
| Slack | Communication | `brew install --cask slack` |

Also mention: Warp (`brew install --cask warp`) as optional.

### Step 3: Confirm
AskUserQuestion — Header: "Install", Options: "Install all", "Select tools" (multiSelect follow-up), "Cancel".

### Step 4: Install
Run selected `brew install` commands. Report progress per tool. Skip already-installed tools.

### Step 5: Configure tmux

If `~/.tmux.conf` exists, ask before overwriting (AskUserQuestion — Header: "Config", Options: "Replace", "Skip").

```bash
cat > ~/.tmux.conf << 'EOF'
# Fix Claude / TUI rendering
set -g mouse on
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -g history-limit 50000
set -s escape-time 0
set -g focus-events on

# Prevent accidental freezes
unbind C-s
unbind C-q

# Quality of life
bind r source-file ~/.tmux.conf \; display "Config reloaded!"
bind | split-window -h
bind - split-window -v
EOF
```

### Step 6: Install Claude Code Plugins
AskUserQuestion — Header: "Plugins", Options: "Install both (Recommended)" (code-simplifier + code-review), "Skip".
```bash
claude plugin install code-simplifier
claude plugin install code-review
```
Note: restart Claude Code after plugin installation.

### Step 7: Summary
Report installed tools, configured tmux, installed plugins. Suggest: set iTerm2 as default terminal, sign in to Linear/Slack, restart Claude Code, run `/forge:start`.

## Error Handling
- Already installed → skip, note | Install fails → show error, continue | No admin rights → suggest sudo
