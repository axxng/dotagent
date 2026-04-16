$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ICloudSpecStory = "$env:USERPROFILE\iCloudDrive\.specstory\history"
$ICloudClaudeProjects = "$env:USERPROFILE\iCloudDrive\Claude\projects"

Write-Host "Setting up dotagent from $RepoDir"

# SpecStory config
New-Item -ItemType Directory -Path "$env:USERPROFILE\.specstory\cli" -Force | Out-Null
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.specstory\cli\config.toml" -Target "$RepoDir\.specstory\cli\config.toml" -Force | Out-Null
Write-Host "[OK] SpecStory config symlinked"

# SpecStory history -> iCloud
if (Test-Path (Split-Path $ICloudSpecStory)) {
    New-Item -ItemType Directory -Path $ICloudSpecStory -Force | Out-Null
    if (-not (Test-Path "$env:USERPROFILE\.specstory\history")) {
        New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.specstory\history" -Target $ICloudSpecStory | Out-Null
        Write-Host "[OK] SpecStory history symlinked to iCloud"
    } else {
        Write-Host "[SKIP] SpecStory history symlink already exists, skipping"
    }
} else {
    Write-Host "[SKIP] iCloud Drive not found, skipping SpecStory history symlink"
}

# Claude Code
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude" -Force | Out-Null
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\CLAUDE.md" -Target "$RepoDir\AGENT.md" -Force | Out-Null
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\settings.json" -Target "$RepoDir\.claude\settings.json" -Force | Out-Null
if (Test-Path "$env:USERPROFILE\.claude\hooks") {
    $existing = Get-Item "$env:USERPROFILE\.claude\hooks"
    if ($existing.LinkType -eq "SymbolicLink") {
        Remove-Item "$env:USERPROFILE\.claude\hooks" -Force -Recurse
    } else {
        $backup = "$env:USERPROFILE\.claude\hooks.bak"
        Write-Host "[SKIP] Backing up existing hooks to $backup"
        if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }
        Move-Item "$env:USERPROFILE\.claude\hooks" $backup
    }
}
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\hooks" -Target "$RepoDir\.claude\hooks" | Out-Null
if (Test-Path "$env:USERPROFILE\.claude\skills") {
    $existing = Get-Item "$env:USERPROFILE\.claude\skills"
    if ($existing.LinkType -eq "SymbolicLink") {
        Remove-Item "$env:USERPROFILE\.claude\skills" -Force -Recurse
    } else {
        $backup = "$env:USERPROFILE\.claude\skills.bak"
        Write-Host "[SKIP] Backing up existing skills to $backup"
        if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }
        Move-Item "$env:USERPROFILE\.claude\skills" $backup
    }
}
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\skills" -Target "$RepoDir\.claude\skills" | Out-Null
Write-Host "[OK] Claude Code config, hooks, and skills symlinked"

# Claude Code projects -> iCloud
if (Test-Path (Split-Path $ICloudClaudeProjects)) {
    New-Item -ItemType Directory -Path $ICloudClaudeProjects -Force | Out-Null
    if (-not (Test-Path "$env:USERPROFILE\.claude\projects" -PathType Container) -or (Get-Item "$env:USERPROFILE\.claude\projects").LinkType -ne "SymbolicLink") {
        if (Test-Path "$env:USERPROFILE\.claude\projects") {
            try {
                Copy-Item "$env:USERPROFILE\.claude\projects\*" $ICloudClaudeProjects -Recurse -Force -ErrorAction Stop
                Remove-Item "$env:USERPROFILE\.claude\projects" -Recurse -Force
            } catch {
                Write-Host "[ERROR] Failed to copy existing projects to iCloud, skipping migration to avoid data loss"
                exit 1
            }
        }
        New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\projects" -Target $ICloudClaudeProjects | Out-Null
        Write-Host "[OK] Claude Code projects symlinked to iCloud"
    } else {
        Write-Host "[SKIP] Claude Code projects symlink already exists, skipping"
    }
} else {
    Write-Host "[SKIP] iCloud Drive not found, skipping Claude Code projects symlink"
}

# Codex
New-Item -ItemType Directory -Path "$env:USERPROFILE\.codex" -Force | Out-Null
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.codex\AGENTS.md" -Target "$RepoDir\AGENT.md" -Force | Out-Null
Write-Host "[OK] Codex config symlinked"

# PATH: ensure %USERPROFILE%\.local\bin is in user PATH
$LocalBin = "$env:USERPROFILE\.local\bin"
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$LocalBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$LocalBin", "User")
    $env:Path = "$env:Path;$LocalBin"
    Write-Host "[OK] Added $LocalBin to user PATH"
} else {
    Write-Host "[SKIP] $LocalBin already in user PATH"
}

# Install Claude Code if not present
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Claude Code..."
    irm https://claude.ai/install.ps1 | iex
    Write-Host "[OK] Claude Code installed"
} else {
    Write-Host "[SKIP] Claude Code already installed"
}

# Install Node.js via winget if not present (needed for Codex)
$NodeDir = "$env:ProgramFiles\nodejs"
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    if (Test-Path "$NodeDir\node.exe") {
        Write-Host "[OK] Node.js found at $NodeDir, adding to session PATH"
    } else {
        Write-Host "Installing Node.js via winget..."
        winget install OpenJS.NodeJS --source winget --accept-source-agreements --accept-package-agreements --silent
        Write-Host "[OK] Node.js installed"
    }
    # Add to current session PATH
    $env:Path = "$env:Path;$NodeDir"
} else {
    Write-Host "[SKIP] Node.js already installed"
}

# Install Codex via npm if not present
if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Codex..."
    npm install -g @openai/codex
    Write-Host "[OK] Codex installed"
} else {
    Write-Host "[SKIP] Codex already installed"
}

# Install Claude Code plugins from settings.json
$SettingsFile = "$RepoDir\.claude\settings.json"
$Settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
$Plugins = $Settings.enabledPlugins.PSObject.Properties.Name
Write-Host ""
Write-Host "Installing Claude Code plugins..."
foreach ($Plugin in $Plugins) {
    Write-Host "  Installing $Plugin..."
    claude plugins install $Plugin 2>$null
}
Write-Host "[OK] Claude Code plugins installed"

Write-Host ""
Write-Host "Done! Restart your terminal for PATH changes to take effect."
Write-Host ""
Write-Host "Note: SpecStory CLI has no Windows installer yet. This is optional --"
Write-Host "Claude Code conversations and project memories sync via iCloud without it."
