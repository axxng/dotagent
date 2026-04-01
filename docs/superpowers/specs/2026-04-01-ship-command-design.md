# `/ship` Command Design

## Problem

The stop hook auto-commits on every Claude turn, creating noisy git history and (previously) pushing half-done work. We want local auto-commits as a safety net, but clean remote history with intentional pushes.

## Solution

Two changes:

1. **Strip push logic from the stop hook** — it becomes commit-only
2. **New `/ship` slash command** — squashes auto-commits into one clean commit and pushes

## Stop Hook Changes

The hook at `.claude/hooks/stop-auto-commit-push.sh` keeps its current auto-commit behavior (`git add -A`, `git commit --no-verify`) but all push logic (the `push_with_retry` function and the branch case statement) is removed entirely. The hook becomes `stop-auto-commit.sh`.

## `/ship` Command Behavior

### Step 1: Find squash boundary

Walk back from HEAD to find the most recent commit whose message does **not** start with `auto:`. This is the squash boundary. All commits after it are candidates for squashing.

If no `auto:` commits exist after the boundary, report "Nothing to ship" and exit.

### Step 2: Handle dirty working tree

If there are uncommitted changes at ship time, stage and commit them as one final `auto:` commit so they're included in the squash.

### Step 3: Squash

Soft-reset to the squash boundary commit (`git reset --soft <boundary>`), which unstages all the auto-commit changes into the index.

### Step 4: Commit message

Ask the user for a commit message via `AskUserQuestion` with two options:
- **Write my own** — user provides a custom message
- **Auto-generate** — summarize the combined diff (files changed, nature of changes)

The commit is created with the co-author trailers per CLAUDE.md.

### Step 5: Push

Push to the remote. If no upstream is set, use `git push -u origin <branch>`.

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| No `auto:` commits | "Nothing to ship" — exit |
| On main/master | Works normally (squash + push) |
| No remote upstream | Sets upstream with `git push -u` |
| Dirty working tree | Auto-commits remaining changes before squash |
| Mixed auto and manual commits | Only squashes the contiguous `auto:` commits from HEAD backwards to the first non-auto commit |

## File Changes

| File | Change |
|------|--------|
| `.claude/hooks/stop-auto-commit-push.sh` | Remove push logic, rename to `stop-auto-commit.sh` |
| `.claude/settings.json` | Update hook path to new filename |
| New skill or script for `/ship` | Implements the squash + push workflow |
