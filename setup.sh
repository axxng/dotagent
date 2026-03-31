#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ICLOUD_SPECSTORY="$HOME/Library/Mobile Documents/com~apple~CloudDocs/.specstory/history"

echo "Setting up dotagent from $REPO_DIR"

# SpecStory config
mkdir -p ~/.specstory/cli
ln -sf "$REPO_DIR/.specstory/cli/config.toml" ~/.specstory/cli/config.toml
echo "✓ SpecStory config symlinked"

# SpecStory history → iCloud
mkdir -p "$ICLOUD_SPECSTORY"
if [ ! -L "$HOME/.specstory/history" ]; then
  ln -s "$ICLOUD_SPECSTORY" "$HOME/.specstory/history"
  echo "✓ SpecStory history symlinked to iCloud"
else
  echo "~ SpecStory history symlink already exists, skipping"
fi

# Claude Code
mkdir -p ~/.claude
ln -sf "$REPO_DIR/AGENT.md" ~/.claude/CLAUDE.md
ln -sf "$REPO_DIR/.claude/settings.json" ~/.claude/settings.json
echo "✓ Claude Code config symlinked"

# Codex
mkdir -p ~/.codex
ln -sf "$REPO_DIR/AGENT.md" ~/.codex/AGENTS.md
echo "✓ Codex config symlinked"

echo ""
echo "Done! Manual steps remaining:"
echo "  1. brew install specstoryai/tap/specstory"
echo "  2. brew install --cask claude-code"
echo "  3. brew install codex"
echo "  4. Install plugins in Claude Code: /plugin install superpowers@superpowers-dev"
