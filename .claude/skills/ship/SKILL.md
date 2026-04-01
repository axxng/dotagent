---
name: ship
description: Squash auto-commits into one clean commit and push
allowed-tools: Bash(git *), Bash(wc *), Bash(head *), AskUserQuestion
disable-model-invocation: true
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Recent commits: !`git log --oneline -20`

## Your task

Squash all contiguous `auto:` commits from HEAD into one clean commit, then push.

### Step 1: Find the squash boundary

Walk backwards from HEAD through the commit log. Find the most recent commit whose message does NOT start with `auto:`. This is the squash boundary.

To identify auto-commits, check if the commit subject starts with `auto:`:
```bash
git log --format="%H %s" | while read hash msg; do
  case "$msg" in
    auto:*) echo "$hash" ;;
    *) break ;;
  esac
done
```

Count the auto-commits. If there are zero, respond with "Nothing to ship — no auto-commits found." and stop.

### Step 2: Handle dirty working tree

Check `git status --short`. If there are uncommitted changes, stage and commit them:
```bash
git add -A
git commit -m "auto: final changes before ship" --no-verify
```

Then re-count the auto-commits (the new one is included).

### Step 3: Get the squash boundary hash

The boundary is the commit just before the oldest contiguous auto-commit from HEAD. Get it with:
```bash
# Get the hash of the oldest auto-commit in the contiguous run
OLDEST_AUTO=$(git log --format="%H %s" | while read hash msg; do case "$msg" in auto:*) echo "$hash" ;; *) break ;; esac; done | tail -1)
BOUNDARY=$(git rev-parse "${OLDEST_AUTO}^")
```

### Step 4: Show summary and ask for commit message

Show the user what will be squashed:
- Number of auto-commits being squashed
- Files changed: `git diff --stat $BOUNDARY HEAD`

Then use `AskUserQuestion` to ask for a commit message with these options:
- **Write my own** — let the user provide a custom message
- **Auto-generate** — generate a message summarizing the changes (e.g., "Update setup scripts and add /ship command")

### Step 5: Squash

```bash
git reset --soft $BOUNDARY
git commit -m "<message>

Co-authored-by: Alex Ng <7019953+axxng@users.noreply.github.com>
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Step 6: Push

Push to the remote. If no upstream is set, use `-u`:
```bash
BRANCH=$(git branch --show-current)
if git rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
  git push
else
  git push -u origin "$BRANCH"
fi
```

If the push fails because the remote has diverged (due to previous squashed pushes), the remote history and local history have diverged because of the squash. Use `git push --force-with-lease` to safely update the remote. Inform the user before doing this.

### Important

- Always include both co-author trailers as the last lines of the commit message.
- Do not use any tools besides git, wc, head, and AskUserQuestion.
- Do not send extra commentary — just execute the steps.
