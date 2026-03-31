# Setup

This setup is specific to using SpecStory and iCloud Drive to sync agent session histories across devices.

1. Install SpecStory: `brew install specstoryai/tap/specstory`

## On macOS

2. Create a `.specstory/history` folder in `"$HOME/Library/Mobile Documents/com~apple~CloudDocs/"`. The final path should look like this: `"$HOME/Library/Mobile Documents/com~apple~CloudDocs/.specstory/history"`

3. Create a symlink `ln -sf <parent path>/dotagent/config.toml ~/.specstory/cli/config.toml`. This makes the SpecStory config file reference what we have in this repo

4. Install Claude Code CLI `brew install --cask claude-code`

5. Create a symlink `ln -sf ~/git-clones/dotagent/AGENT.md ~/.claude/CLAUDE.md`. This makes the CLAUDE.md file reference our AGENT.md so we can have the same agent config across the board

6. Install Codex CLI `brew install codex`

7. Create a symlink `ln -sf ~/git-clones/dotagent/AGENT.md ~/.codex/AGENTS.md`. Codex references AGENTS.md in the root, we now point it to the same agent config we have
