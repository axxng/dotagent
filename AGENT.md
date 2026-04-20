## Bash Commands

Prefer separate bash tool calls over compound commands (`&&`, `;`). This allows individual commands to match the allow list and auto-approve without manual intervention. Pipes are fine — they represent a single logical operation.

## Writing

When asked to write, follow: https://github.com/axxng/chatgpt-custom-instruction/blob/main/natural-writing-guide.md

## Git Commits

All commits to GitHub must include the co-author trailers as the **last lines** of the commit message (after any URLs or other content), so GitHub properly recognizes them:

Co-authored-by: Alex Ng <7019953+axxng@users.noreply.github.com>

If you are Claude (Anthropic), add:
Co-Authored-By: Claude <noreply@anthropic.com>

If you are Codex (OpenAI), add:
Co-Authored-By: Codex <noreply@openai.com>
