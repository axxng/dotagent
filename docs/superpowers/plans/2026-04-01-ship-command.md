# `/ship` Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a `/ship` slash command that squashes contiguous `auto:` commits from HEAD into one clean commit and pushes, plus strip push logic from the stop hook.

**Architecture:** A project-local Claude Code skill (`.claude/skills/ship/SKILL.md`) that uses dynamic context injection to gather git state, then instructs Claude to perform the squash-commit-push workflow. The stop hook is simplified to commit-only.

**Tech Stack:** Bash (git), Claude Code skills (markdown + YAML frontmatter)

---

### Task 1: Strip push logic from the stop hook

**Files:**
- Modify: `.claude/hooks/stop-auto-commit-push.sh` (rename to `stop-auto-commit.sh`)
- Modify: `.claude/settings.json` (update hook path)

- [ ] **Step 1: Create the new commit-only hook**

Create `.claude/hooks/stop-auto-commit.sh` with the commit logic only — no push:

```bash
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
```

- [ ] **Step 2: Delete the old hook file**

```bash
rm .claude/hooks/stop-auto-commit-push.sh
```

- [ ] **Step 3: Make the new hook executable**

```bash
chmod +x .claude/hooks/stop-auto-commit.sh
```

- [ ] **Step 4: Update settings.json hook path**

In `.claude/settings.json`, change the hook command from:
```json
"command": "~/.claude/hooks/stop-auto-commit-push.sh"
```
to:
```json
"command": "~/.claude/hooks/stop-auto-commit.sh"
```

Also update the `statusMessage` from `"Auto-committing and pushing..."` to `"Auto-committing..."`.

- [ ] **Step 5: Commit**

```bash
git add .claude/hooks/stop-auto-commit.sh .claude/settings.json
git rm .claude/hooks/stop-auto-commit-push.sh
git commit -m "Simplify stop hook to commit-only, remove auto-push

Pushing is now handled by the /ship command instead of the stop hook.

Co-authored-by: Alex Ng <7019953+axxng@users.noreply.github.com>
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: Create the `/ship` skill

**Files:**
- Create: `.claude/skills/ship/SKILL.md`

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p .claude/skills/ship
```

- [ ] **Step 2: Write the skill file**

Create `.claude/skills/ship/SKILL.md`:

````markdown
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
````

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/ship/SKILL.md
git commit -m "Add /ship command to squash auto-commits and push

New project-local skill that squashes contiguous auto: commits from
HEAD into a single clean commit with a proper message, then pushes.

Co-authored-by: Alex Ng <7019953+axxng@users.noreply.github.com>
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: Update the setup scripts to handle the renamed hook

**Files:**
- Modify: `setup.sh`
- Modify: `setup.ps1`

The setup scripts symlink `.claude/hooks/` as a directory, so the rename is automatically picked up — no changes needed to the scripts themselves. However, the `README.md` may reference the old hook name.

- [ ] **Step 1: Check README.md for references to the old hook name**

```bash
grep -n "stop-auto-commit-push" README.md
```

If found, update references to `stop-auto-commit.sh`.

- [ ] **Step 2: Commit if changes were made**

```bash
git add README.md
git commit -m "Update README to reference renamed stop hook

Co-authored-by: Alex Ng <7019953+axxng@users.noreply.github.com>
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: Test the full workflow

- [ ] **Step 1: Verify the stop hook no longer pushes**

Make a small change on a test branch, let Claude respond (triggering the stop hook), then verify:
```bash
git status --short --branch
```

Expected: branch is ahead of origin (committed but not pushed).

- [ ] **Step 2: Test `/ship` with auto-commits**

Run `/ship` and verify:
- It finds the auto-commits
- Shows the summary
- Asks for a commit message
- Squashes and pushes

- [ ] **Step 3: Test `/ship` with no auto-commits**

Run `/ship` when there are no `auto:` commits. Expected: "Nothing to ship" message.

- [ ] **Step 4: Test `/ship` with dirty working tree**

Make uncommitted changes, then run `/ship`. Expected: changes are included in the squashed commit.
