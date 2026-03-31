# Setup

This setup is specific to using SpecStory and iCloud Drive to sync agent session histories across devices.

## On macOS

1. Run `./setup.sh` to create all symlinks (SpecStory, Claude Code, Codex)

2. Install the CLIs:
   - `brew install specstoryai/tap/specstory`
   - `brew install --cask claude-code`
   - `brew install codex`

3. Install plugins in Claude Code via `/plugin install <plugin>@<marketplace>` as listed in `.claude/settings.json`

## On Windows

1. Run `.\setup.ps1` in PowerShell (as Administrator) to create all symlinks

2. Install the CLIs:
   - Install SpecStory: https://github.com/specstoryai/specstory
   - Install Claude Code: `irm https://claude.ai/install.ps1 | iex`
   - Install Codex: `npm install -g @openai/codex`

3. Install plugins in Claude Code via `/plugin install <plugin>@<marketplace>` as listed in `.claude/settings.json`
