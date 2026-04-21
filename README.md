# dotagent

Syncs Claude Code config, project memories, and conversation history across devices via iCloud Drive. Also sets up Codex and SpecStory.

## What it syncs

- Claude Code settings, hooks, skills, and CLAUDE.md
- Claude Code project memories and conversations (via iCloud)
- SpecStory config and history (via iCloud)
- Codex AGENTS.md and skills

## What it installs

- Claude Code, Codex, Python (via pyenv), SpecStory (macOS)
- Claude Code plugins enabled in `.claude/settings.json`
- [GSD](https://github.com/gsd-build/get-shit-done) skills for both Claude Code and Codex

## On macOS

Run `./setup.sh` to create all symlinks, install CLIs (via Homebrew), and install Claude Code plugins.

Requires [Homebrew](https://brew.sh) to be installed first.

## On Windows

Run `.\setup.ps1` in PowerShell (as Administrator) to create all symlinks, install CLIs (via winget/npm), and install Claude Code plugins.

SpecStory CLI has no Windows installer yet. This is optional -- Claude Code conversations and project memories sync via iCloud without it.
