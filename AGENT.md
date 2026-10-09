## Bash Commands

Prefer separate bash tool calls over compound commands (`&&`, `;`). This allows individual commands to match the allow list and auto-approve without manual intervention. Pipes are fine — they represent a single logical operation.

## Writing

When asked to write, follow: https://github.com/axxng/chatgpt-custom-instruction/blob/main/natural-writing-guide.md

## My Brain Repo

I keep my portable brain in a private repo: github.com/axxng/eight. It's the one place my context lands no matter which assistant I talk to. Its AGENTS.md is the source of truth for how to read and write it. Follow that over anything here.

- **At the start of a session,** pull it and read AGENTS.md, then memory/MEMORY.md and the knowledge/ files. Use sessions/ to pick up where I left off and meeting-notes/ for my meetings. Don't ask me for something that's already in there.
- **Before you finish,** write back what you learned without waiting for me to ask. Harvest from your own tool's store too: crawl all of ~/.claude if you're Claude, or ~/.codex if you're Codex, not only a memory/ folder. Then do a mining pass over ~/.specstory/history. Distill facts, never copy transcripts in.
- **Reconcile, don't overwrite.** Update an existing entry instead of adding a second copy, and stamp source (assistant · machine) and date.
- **personality/, conversations/ and config/ are off-limits.** They belong to Eight and her engine.
- Commit with the prefixes AGENTS.md lists, push, and tell me whether the push went through.

## Git Commits

All commits to GitHub must include the co-author trailers as the **last lines** of the commit message (after any URLs or other content), so GitHub properly recognizes them:

Co-authored-by: Alex Ng <7019953+axxng@users.noreply.github.com>

If you are Claude (Anthropic), add:
Co-Authored-By: Claude <noreply@anthropic.com>

If you are Codex (OpenAI), add:
Co-Authored-By: Codex <noreply@openai.com>
