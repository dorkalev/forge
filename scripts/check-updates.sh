#!/bin/bash
# Check for forge plugin updates on session start

LOCAL_VERSION="1.1.0"
CACHE_FILE="$HOME/.cache/forge-update-check"
CACHE_TTL=86400  # 24 hours in seconds

# Only check once per day to avoid slowing down session start
if [ -f "$CACHE_FILE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)))
    if [ "$CACHE_AGE" -lt "$CACHE_TTL" ]; then
        # Cache is fresh, read cached result
        cat "$CACHE_FILE" 2>/dev/null
        exit 0
    fi
fi

# Fetch remote version (with timeout to not block session)
REMOTE_VERSION=$(curl -s --max-time 3 https://raw.githubusercontent.com/dorkalev/forge/main/.claude-plugin/plugin.json 2>/dev/null | grep '"version"' | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/')

# Create cache directory if needed
mkdir -p "$(dirname "$CACHE_FILE")"

# Compare versions and cache result
if [ -n "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
    MESSAGE="forge update available: $REMOTE_VERSION (you have $LOCAL_VERSION). Run: /plugin update forge@dorkalev/forge"
    echo "$MESSAGE" > "$CACHE_FILE"
    echo "$MESSAGE"
else
    # Clear cache if up to date
    echo "" > "$CACHE_FILE"
fi
