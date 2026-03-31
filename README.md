# Setup

This setup is specific to using SpecStory and iCloud Drive to sync agent session histories across devices.

1. Install SpecStory: `brew install specstoryai/tap/specstory`

## On macOS

2. Run `./setup.sh` to create all symlinks (SpecStory, Claude Code, Codex)

3. Install the CLIs:
   - `brew install specstoryai/tap/specstory`
   - `brew install --cask claude-code`
   - `brew install codex`

4. Install plugins in Claude Code via `/plugin install <plugin>@<marketplace>` as listed in `.claude/settings.json`
