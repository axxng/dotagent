$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ICloudSpecStory = "$env:USERPROFILE\iCloudDrive\.specstory\history"
$ICloudClaudeProjects = "$env:USERPROFILE\iCloudDrive\Claude\projects"

Write-Host "Setting up dotagent from $RepoDir"

# SpecStory config
New-Item -ItemType Directory -Path "$env:USERPROFILE\.specstory\cli" -Force | Out-Null
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.specstory\cli\config.toml" -Target "$RepoDir\.specstory\cli\config.toml" -Force | Out-Null
Write-Host "✓ SpecStory config symlinked"

# SpecStory history → iCloud
if (Test-Path (Split-Path $ICloudSpecStory)) {
    New-Item -ItemType Directory -Path $ICloudSpecStory -Force | Out-Null
    if (-not (Test-Path "$env:USERPROFILE\.specstory\history")) {
        New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.specstory\history" -Target $ICloudSpecStory | Out-Null
        Write-Host "✓ SpecStory history symlinked to iCloud"
    } else {
        Write-Host "~ SpecStory history symlink already exists, skipping"
    }
} else {
    Write-Host "~ iCloud Drive not found, skipping SpecStory history symlink"
}

# Claude Code
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude" -Force | Out-Null
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\CLAUDE.md" -Target "$RepoDir\AGENT.md" -Force | Out-Null
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\settings.json" -Target "$RepoDir\.claude\settings.json" -Force | Out-Null
if (Test-Path "$env:USERPROFILE\.claude\hooks") {
    $existing = Get-Item "$env:USERPROFILE\.claude\hooks"
    if ($existing.LinkType -eq "SymbolicLink") {
        Remove-Item "$env:USERPROFILE\.claude\hooks" -Force
    } else {
        $backup = "$env:USERPROFILE\.claude\hooks.bak"
        Write-Host "~ Backing up existing hooks to $backup"
        if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }
        Move-Item "$env:USERPROFILE\.claude\hooks" $backup
    }
}
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\hooks" -Target "$RepoDir\.claude\hooks" | Out-Null
Write-Host "✓ Claude Code config and hooks symlinked"

# Claude Code projects → iCloud
if (Test-Path (Split-Path $ICloudClaudeProjects)) {
    New-Item -ItemType Directory -Path $ICloudClaudeProjects -Force | Out-Null
    if (-not (Test-Path "$env:USERPROFILE\.claude\projects" -PathType Container) -or (Get-Item "$env:USERPROFILE\.claude\projects").LinkType -ne "SymbolicLink") {
        if (Test-Path "$env:USERPROFILE\.claude\projects") {
            try {
                Copy-Item "$env:USERPROFILE\.claude\projects\*" $ICloudClaudeProjects -Recurse -Force -ErrorAction Stop
                Remove-Item "$env:USERPROFILE\.claude\projects" -Recurse -Force
            } catch {
                Write-Host "⚠ Failed to copy existing projects to iCloud, skipping migration to avoid data loss"
                exit 1
            }
        }
        New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\projects" -Target $ICloudClaudeProjects | Out-Null
        Write-Host "✓ Claude Code projects symlinked to iCloud"
    } else {
        Write-Host "~ Claude Code projects symlink already exists, skipping"
    }
} else {
    Write-Host "~ iCloud Drive not found, skipping Claude Code projects symlink"
}

# Codex
New-Item -ItemType Directory -Path "$env:USERPROFILE\.codex" -Force | Out-Null
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.codex\AGENTS.md" -Target "$RepoDir\AGENT.md" -Force | Out-Null
Write-Host "✓ Codex config symlinked"

Write-Host ""
Write-Host "Done! Manual steps remaining:"
Write-Host "  1. Install SpecStory: https://github.com/specstoryai/specstory"
Write-Host "  2. Install Claude Code: irm https://claude.ai/install.ps1 | iex"
Write-Host "  3. Install Codex: npm install -g @openai/codex"
Write-Host "  4. Install plugins in Claude Code via /plugin install <plugin>@<marketplace>"
