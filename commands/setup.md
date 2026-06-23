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
| iTerm2 | Terminal (used for `claude attach`) | `brew install --cask iterm2` |
| Marta | Dual-pane file manager | `brew install --cask marta` |
| Meld | Visual diff/merge | `brew install --cask meld` |
| Linear | Issue tracking | `brew install --cask linear-linear` |
| Slack | Communication | `brew install --cask slack` |

Also mention: Warp (`brew install --cask warp`) as optional.

### Step 3: Confirm
AskUserQuestion — Header: "Install", Options: "Install all", "Select tools" (multiSelect follow-up), "Cancel".

### Step 4: Install
Run selected `brew install` commands. Report progress per tool. Skip already-installed tools.

### Step 5: Install Claude Code Plugins
AskUserQuestion — Header: "Plugins", Options: "Install both (Recommended)" (code-simplifier + code-review), "Skip".
```bash
claude plugin install code-simplifier
claude plugin install code-review
```
Note: restart Claude Code after plugin installation.

### Step 6: Summary
Report installed tools and plugins. Suggest: set iTerm2 as default terminal, sign in to Linear/Slack, restart Claude Code, run `/forge:start`. Background agents are monitored with `claude agents` — no extra tooling needed.

## Error Handling
- Already installed → skip, note | Install fails → show error, continue | No admin rights → suggest sudo
