---
name: ship
description: Squash auto-commits into one clean commit and push
allowed-tools: Bash(git *), AskUserQuestion
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Recent commits: !`git log --oneline -20`

## Your task

Squash all contiguous `auto:` commits from HEAD into one clean commit, then push.

### Step 1: Find the squash boundary

Run:
```bash
git log --format="%H %s"
```

Read the output and identify the contiguous run of commits from HEAD whose subject starts with `auto:`. Stop at the first commit that does not start with `auto:`.

If there are zero auto-commits, respond with "Nothing to ship — no auto-commits found." and stop.

Note the hash of the oldest auto-commit in the contiguous run.

### Step 2: Handle dirty working tree

Run:
```bash
git status --short
```

If there are uncommitted changes, stage and commit them:
```bash
git add -A
git commit -m "auto: final changes before ship" --no-verify
```

Then re-run `git log --format="%H %s"` and re-identify the auto-commits (the new one is included).

### Step 3: Get the squash boundary hash

Check if the oldest auto-commit is the root commit:
```bash
git rev-parse <OLDEST_AUTO_HASH>^
```

- If this succeeds, the boundary is the returned parent hash.
- If it fails (no parent), this is the root commit case — set boundary to empty.

### Step 4: Show summary and ask for commit message

Show the user what will be squashed:
- Number of auto-commits being squashed
- Files changed: `git diff --stat <BOUNDARY> HEAD` (or `git diff --stat --root HEAD` if root case)

Then use `AskUserQuestion` to ask for a commit message with these options:
- **Write my own** — let the user provide a custom message
- **Auto-generate** — generate a message summarizing the changes (e.g., "Update setup scripts and add /ship command")

### Step 5: Squash

If boundary is empty (root commit case), reset to the empty tree so all files stay staged but no commit ref is destroyed:
```bash
git reset --soft $(git hash-object -t tree /dev/null)
git commit -m "<message>

Co-authored-by: Alex Ng <7019953+axxng@users.noreply.github.com>
Co-Authored-By: Claude <noreply@anthropic.com>"
```

Otherwise:
```bash
git reset --soft <BOUNDARY>
git commit -m "<message>

Co-authored-by: Alex Ng <7019953+axxng@users.noreply.github.com>
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Step 6: Push

Check for upstream and push:
```bash
git rev-parse --abbrev-ref @{upstream}
```

- If upstream exists: `git push`
- If no upstream: `git push -u origin <BRANCH>`

If the push fails because the remote has diverged (due to previous squashed pushes), the remote history and local history have diverged because of the squash. Use `git push --force-with-lease` to safely update the remote. Inform the user before doing this.

### Important

- Always include both co-author trailers as the last lines of the commit message.
- Use only simple `git` commands — no shell pipes, variable assignments, or compound commands. Parse command output yourself instead.
- Do not send extra commentary — just execute the steps.
