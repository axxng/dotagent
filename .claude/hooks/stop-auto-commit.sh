#!/bin/bash
# Claude Code Stop hook: auto-commit after each turn.
# Commits all changes with an auto-generated message.
# Pushing is handled separately by /ship.

# Only run inside a git repo
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Only run if there are uncommitted changes (staged, unstaged, or untracked)
if git diff --quiet HEAD 2>/dev/null && git diff --cached --quiet 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  exit 0
fi

# Stage all changes
git add -A

# Build commit message from changed files
CHANGED=$(git diff --cached --name-only | head -20)
COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')
if [ "$COUNT" -le 5 ]; then
  MSG="auto: update $CHANGED"
else
  MSG="auto: update $COUNT files"
fi

# Commit
git commit -m "$MSG" --no-verify >/dev/null 2>&1 || exit 0
