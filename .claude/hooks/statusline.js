#!/usr/bin/env node
// Custom Claude Code statusline.
// Shows: directory · git branch (+dirty marker) · model · context-usage meter.
// Reads the session JSON that Claude Code pipes in on stdin.

const { execFileSync } = require('child_process');
const os = require('os');

// ANSI helpers
const c = (code, s) => `\x1b[${code}m${s}\x1b[0m`;
const cyan = (s) => c('36', s);
const magenta = (s) => c('35', s);
const yellow = (s) => c('33', s);
const dim = (s) => c('2', s);

function readStdin() {
  try {
    return require('fs').readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

// Shorten an absolute path, collapsing $HOME to ~
function shortenDir(dir) {
  const home = os.homedir();
  if (dir === home) return '~';
  if (dir.startsWith(home + '/')) return '~' + dir.slice(home.length);
  return dir;
}

// Git branch + dirty flag, scoped to the session's cwd. Empty string if not a repo.
function gitSegment(cwd) {
  try {
    const opts = { cwd, stdio: ['ignore', 'pipe', 'ignore'], encoding: 'utf8' };
    const git = (args) => execFileSync('git', args, opts);
    const branch = git(['rev-parse', '--abbrev-ref', 'HEAD']).trim();
    if (!branch) return '';
    const dirty = git(['status', '--porcelain']).trim().length > 0;
    const label = magenta('⎇ ' + branch) + (dirty ? yellow('*') : '');
    return '  ' + label;
  } catch {
    return '';
  }
}

// Context-usage meter, normalized to usable context (accounts for the
// autocompact buffer) so it matches what /context reports as usable.
function contextSegment(data) {
  const remaining = data.context_window?.remaining_percentage;
  if (remaining == null) return '';

  const totalCtx = data.context_window?.total_tokens || 1_000_000;
  const acw = parseInt(process.env.CLAUDE_CODE_AUTO_COMPACT_WINDOW || '0', 10);
  const bufferPct = acw > 0 ? Math.min(100, (acw / totalCtx) * 100) : 16.5;

  const usableRemaining = Math.max(0, ((remaining - bufferPct) / (100 - bufferPct)) * 100);
  const used = Math.max(0, Math.min(100, Math.round(100 - usableRemaining)));

  const filled = Math.floor(used / 10);
  const bar = '█'.repeat(filled) + '░'.repeat(10 - filled);

  let code;                       // green → yellow → orange → red
  if (used < 50) code = '32';
  else if (used < 65) code = '33';
  else if (used < 80) code = '38;5;208';
  else code = '31';
  return '  ' + c(code, `${bar} ${used}%`);
}

function main() {
  let data = {};
  try { data = JSON.parse(readStdin()) || {}; } catch { /* fall back to defaults */ }

  const cwd = data.workspace?.current_dir || process.cwd();
  const model = data.model?.display_name || 'Claude';

  const parts = [
    cyan(shortenDir(cwd)),
    gitSegment(cwd),
    '  ' + dim('· ' + model),
    contextSegment(data),
  ];
  process.stdout.write(parts.join(''));
}

main();
