## Bash Commands

Prefer separate bash tool calls over compound commands (`&&`, `;`). This allows individual commands to match the allow list and auto-approve without manual intervention. Pipes are fine — they represent a single logical operation.

## Writing

When asked to write, follow: https://github.com/axxng/chatgpt-custom-instruction/blob/main/natural-writing-guide.md

## My Brain Repo

I keep my portable brain in a private repo: github.com/axxng/eight. At the start of every conversation, read it before you answer, using whatever access you have: a local clone (git pull first), a GitHub connector, or, if you're in a browser, open github.com/axxng/eight in a new tab and read the files there. If one way doesn't work, try the next. Don't stop at a failed pull. Read AGENTS.md at its root first and follow it over anything here, then CORE.md, which has who I am, how I work and what I'm working on. Don't read the rest up front: when a topic comes up, open the index CORE.md points to for it, then only the entries that matter. Check there before you ask me anything.

personality/, conversations/ and config/ are off-limits (they're Eight's), and you may contribute to everything else. Before a conversation ends, save what came up in it without waiting for me to ask: durable facts, plus a sessions/ update if we moved work forward, following the writing routine in AGENTS.md. Update what's already there instead of adding a second copy. Commit and push however you can (git, the connector, or GitHub's web editor), and tell me whether it went through. Only crawl your tool's whole store or ~/.specstory when I ask for a full harvest.

## Git Commits

All commits to GitHub must include the co-author trailers as the **last lines** of the commit message (after any URLs or other content), so GitHub properly recognizes them:

Co-authored-by: Alex Ng <7019953+axxng@users.noreply.github.com>

If you are Claude (Anthropic), add:
Co-Authored-By: Claude <noreply@anthropic.com>

If you are Codex (OpenAI), add:
Co-Authored-By: Codex <noreply@openai.com>
