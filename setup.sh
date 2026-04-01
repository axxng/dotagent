#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ICLOUD_SPECSTORY="$HOME/Library/Mobile Documents/com~apple~CloudDocs/.specstory/history"
ICLOUD_CLAUDE_PROJECTS="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Claude/projects"

echo "Setting up dotagent from $REPO_DIR"

# SpecStory config
mkdir -p ~/.specstory/cli
ln -sf "$REPO_DIR/.specstory/cli/config.toml" ~/.specstory/cli/config.toml
echo "✓ SpecStory config symlinked"

# SpecStory history → iCloud
mkdir -p "$ICLOUD_SPECSTORY"
if [ -L "$HOME/.specstory/history" ]; then
  echo "~ SpecStory history symlink already exists, skipping"
elif [ -d "$HOME/.specstory/history" ]; then
  echo "~ Migrating existing SpecStory history to iCloud"
  cp -R "$HOME/.specstory/history/"* "$ICLOUD_SPECSTORY/" 2>/dev/null || true
  rm -rf "$HOME/.specstory/history"
  ln -s "$ICLOUD_SPECSTORY" "$HOME/.specstory/history"
  echo "✓ SpecStory history migrated and symlinked to iCloud"
else
  ln -s "$ICLOUD_SPECSTORY" "$HOME/.specstory/history"
  echo "✓ SpecStory history symlinked to iCloud"
fi

# Claude Code
mkdir -p ~/.claude
ln -sf "$REPO_DIR/AGENT.md" ~/.claude/CLAUDE.md
ln -sf "$REPO_DIR/.claude/settings.json" ~/.claude/settings.json
ln -sfn "$REPO_DIR/.claude/hooks" ~/.claude/hooks
ln -sfn "$REPO_DIR/.claude/skills" ~/.claude/skills
echo "✓ Claude Code config, hooks, and skills symlinked"

# Claude Code projects → iCloud
mkdir -p "$ICLOUD_CLAUDE_PROJECTS"
if [ ! -L "$HOME/.claude/projects" ]; then
  if [ -d "$HOME/.claude/projects" ]; then
    if cp -R "$HOME/.claude/projects/"* "$ICLOUD_CLAUDE_PROJECTS/" 2>/dev/null; then
      rm -rf "$HOME/.claude/projects"
    else
      echo "⚠ Failed to copy existing projects to iCloud, skipping migration to avoid data loss"
      exit 1
    fi
  fi
  ln -s "$ICLOUD_CLAUDE_PROJECTS" "$HOME/.claude/projects"
  echo "✓ Claude Code projects symlinked to iCloud"
else
  echo "~ Claude Code projects symlink already exists, skipping"
fi

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
