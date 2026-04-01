#!/bin/bash
# Claude Code Stop hook: auto-commit and conditional push after each turn.
# Commits all changes with an auto-generated message, then pushes if the
# branch tracks a remote and isn't main/master.

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

# Push with retry (3 attempts, 2s between)
push_with_retry() {
  for i in 1 2 3; do
    git push --no-verify 2>/dev/null && return 0
    [ "$i" -lt 3 ] && sleep 2
  done
  return 1
}

# Push only if branch tracks a remote and isn't main/master
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
case "$BRANCH" in
  main|master)
    # Never auto-push protected branches
    ;;
  *)
    if git rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
      push_with_retry || true
    fi
    ;;
esac
