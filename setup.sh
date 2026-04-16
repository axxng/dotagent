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
  if cp -a "$HOME/.specstory/history/." "$ICLOUD_SPECSTORY/"; then
    rm -rf "$HOME/.specstory/history"
    ln -s "$ICLOUD_SPECSTORY" "$HOME/.specstory/history"
    echo "✓ SpecStory history migrated and symlinked to iCloud"
  else
    echo "⚠ Failed to copy SpecStory history to iCloud, skipping migration to avoid data loss"
    exit 1
  fi
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

# Install tools via brew
if command -v brew &>/dev/null; then
  if ! command -v specstory &>/dev/null; then
    echo "Installing SpecStory..."
    brew install specstoryai/tap/specstory
    echo "OK SpecStory installed"
  else
    echo "~ SpecStory already installed, skipping"
  fi

  if ! command -v claude &>/dev/null; then
    echo "Installing Claude Code..."
    brew install --cask claude-code
    echo "OK Claude Code installed"
  else
    echo "~ Claude Code already installed, skipping"
  fi

  if ! command -v codex &>/dev/null; then
    echo "Installing Codex..."
    brew install codex
    echo "OK Codex installed"
  else
    echo "~ Codex already installed, skipping"
  fi
else
  echo "WARNING: brew not found. Install Homebrew first: https://brew.sh"
  echo "Then install manually: brew install specstoryai/tap/specstory && brew install --cask claude-code && brew install codex"
fi

# Install Claude Code plugins from settings.json
if command -v claude &>/dev/null; then
  echo ""
  echo "Installing Claude Code plugins..."
  SETTINGS_FILE="$REPO_DIR/.claude/settings.json"
  for plugin in $(python3 -c "import json; d=json.load(open('$SETTINGS_FILE')); print('\n'.join(d.get('enabledPlugins',{}).keys()))"); do
    echo "  Installing $plugin..."
    claude plugins install "$plugin" 2>/dev/null || true
  done
  echo "OK Claude Code plugins installed"
else
  echo "WARNING: claude not found, skipping plugin installation"
fi

echo ""
echo "Done!"
