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
mkdir -p "$REPO_DIR/.codex/skills"
if [ -L "$HOME/.codex/skills" ]; then
  ln -sfn "$REPO_DIR/.codex/skills" ~/.codex/skills
elif [ -d "$HOME/.codex/skills" ]; then
  backup="$HOME/.codex/skills.bak"
  echo "~ Backing up existing Codex skills to $backup"
  rm -rf "$backup"
  mv "$HOME/.codex/skills" "$backup"
  ln -s "$REPO_DIR/.codex/skills" ~/.codex/skills
else
  ln -s "$REPO_DIR/.codex/skills" ~/.codex/skills
fi
echo "✓ Codex config and skills symlinked"

# Python via pyenv
if command -v pyenv &>/dev/null; then
  echo "~ pyenv already installed, updating..."
  if command -v brew &>/dev/null && brew list pyenv &>/dev/null; then
    brew upgrade pyenv 2>/dev/null || true
  else
    pyenv update 2>/dev/null || true
  fi
else
  if command -v brew &>/dev/null; then
    echo "Installing pyenv via brew..."
    brew install pyenv
    echo "OK pyenv installed"
  else
    echo "Installing pyenv via installer..."
    curl -fsSL https://pyenv.run | bash
    echo "OK pyenv installed"
  fi
fi

# Ensure pyenv is on PATH for this session
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
eval "$(pyenv init -)" 2>/dev/null || true

LATEST_PYTHON=$(pyenv install --list | grep -E '^\s+3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
echo "Latest stable Python: $LATEST_PYTHON"

if pyenv versions --bare | grep -q "$LATEST_PYTHON"; then
  echo "~ Python $LATEST_PYTHON already installed via pyenv, skipping"
else
  echo "Installing Python $LATEST_PYTHON via pyenv..."
  # On macOS with Homebrew, pin openssl@3 to avoid linking against a stale openssl@1.1
  if [ "$(uname)" = "Darwin" ] && command -v brew &>/dev/null && brew --prefix openssl@3 &>/dev/null; then
    OPENSSL_PREFIX="$(brew --prefix openssl@3)"
    LDFLAGS="-L${OPENSSL_PREFIX}/lib" CPPFLAGS="-I${OPENSSL_PREFIX}/include" \
      PKG_CONFIG_PATH="${OPENSSL_PREFIX}/lib/pkgconfig" \
      pyenv install "$LATEST_PYTHON"
  else
    pyenv install "$LATEST_PYTHON"
  fi
  echo "OK Python $LATEST_PYTHON installed"
fi

pyenv global "$LATEST_PYTHON"
echo "✓ Python $(python3 --version) set as global"

# Add pyenv init to shell profile if not already there
SHELL_PROFILE=""
if [ -f "$HOME/.zshrc" ]; then
  SHELL_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_PROFILE="$HOME/.bashrc"
fi

if [ -n "$SHELL_PROFILE" ] && ! grep -q "pyenv init" "$SHELL_PROFILE" 2>/dev/null; then
  cat >> "$SHELL_PROFILE" << 'PYENV_INIT'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
PYENV_INIT
  echo "✓ pyenv init added to $SHELL_PROFILE"
else
  echo "~ pyenv init already in shell profile, skipping"
fi

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
    claude plugins install "$plugin" --scope user 2>/dev/null || true
  done
  echo "OK Claude Code plugins installed"
else
  echo "WARNING: claude not found, skipping plugin installation"
fi

# Install Get Shit Done (GSD) skills for Claude Code and Codex
echo ""
if command -v npx &>/dev/null; then
  if [ -f "$HOME/.claude/gsd-file-manifest.json" ]; then
    echo "~ GSD already installed for Claude Code, skipping"
  else
    echo "Installing GSD for Claude Code..."
    npx -y get-shit-done-cc@latest --claude --global
    echo "OK GSD installed for Claude Code"
  fi
  if [ -f "$HOME/.codex/gsd-file-manifest.json" ]; then
    echo "~ GSD already installed for Codex, skipping"
  else
    echo "Installing GSD for Codex..."
    npx -y get-shit-done-cc@latest --codex --global
    echo "OK GSD installed for Codex"
  fi

  # Install GSD SDK (its bundled self-build step is flaky; install the published
  # package directly so /gsd-* commands and programmatic usage work)
  if command -v gsd-sdk &>/dev/null; then
    echo "~ GSD SDK already installed, skipping"
  else
    echo "Installing GSD SDK..."
    npm install -g @gsd-build/sdk
    echo "OK GSD SDK installed"
  fi
else
  echo "WARNING: npx not found, skipping GSD installation"
fi

echo ""
echo "Done!"
