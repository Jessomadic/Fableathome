<#
.SYNOPSIS
    Installs (or uninstalls) the Fableathome harness for Claude Code.

.DESCRIPTION
    Deploys the behavioral core, skills, and subagents so Claude Code picks
    them up. Global scope installs to ~/.claude and applies to every project
    on this machine; project scope installs into a single repository.

    The behavioral core is wired in via an @import line added to CLAUDE.md
    inside a clearly marked block. Existing CLAUDE.md content is never
    touched; re-running the installer is a no-op-safe upgrade.

.EXAMPLE
    .\install.ps1
    Install globally (~/.claude).

.EXAMPLE
    .\install.ps1 -Scope project -Target C:\code\myapp
    Install into a single project.

.EXAMPLE
    .\install.ps1 -Uninstall
    Remove the global install (skills, agents, core, and the CLAUDE.md block).
#>
[CmdletBinding()]
param(
    [ValidateSet('global', 'project')]
    [string]$Scope = 'global',

    [string]$Target = '.',

    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$SourceRoot  = $PSScriptRoot
$MarkerStart = '# >>> fableathome >>>'
$MarkerEnd   = '# <<< fableathome <<<'
$SkillNames  = @('deepthink', 'verify-loop', 'checkpoint', 'council')
$AgentFiles  = @('fable-planner.md', 'fable-critic.md', 'fable-explorer.md')

# Resolve destinations for the chosen scope.
if ($Scope -eq 'global') {
    $ClaudeDir    = Join-Path $env:USERPROFILE '.claude'
    $ClaudeMdPath = Join-Path $ClaudeDir 'CLAUDE.md'
    $ImportLine   = '@fable/fable-core.md'
} else {
    if (-not (Test-Path $Target)) {
        throw "Target directory does not exist: $Target"
    }
    $TargetRoot   = (Resolve-Path $Target).Path
    $ClaudeDir    = Join-Path $TargetRoot '.claude'
    $ClaudeMdPath = Join-Path $TargetRoot 'CLAUDE.md'
    $ImportLine   = '@.claude/fable/fable-core.md'
}

$FableDir  = Join-Path $ClaudeDir 'fable'
$SkillsDir = Join-Path $ClaudeDir 'skills'
$AgentsDir = Join-Path $ClaudeDir 'agents'

function Remove-MarkerBlock {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    $content = Get-Content $Path -Raw
    $pattern = "(?s)\r?\n?" + [regex]::Escape($MarkerStart) + ".*?" + [regex]::Escape($MarkerEnd) + "\r?\n?"
    $updated = [regex]::Replace($content, $pattern, "`r`n")
    if ($updated -ne $content) {
        Set-Content -Path $Path -Value $updated.TrimEnd() -Encoding utf8
    }
}

if ($Uninstall) {
    Write-Host "Uninstalling Fableathome ($Scope scope)..." -ForegroundColor Cyan

    foreach ($name in $SkillNames) {
        $dir = Join-Path $SkillsDir $name
        if (Test-Path $dir) {
            Remove-Item -Recurse -Force $dir -Confirm:$false
            Write-Host "  removed skill  $name"
        }
    }
    foreach ($file in $AgentFiles) {
        $path = Join-Path $AgentsDir $file
        if (Test-Path $path) {
            Remove-Item -Force $path -Confirm:$false
            Write-Host "  removed agent  $file"
        }
    }
    if (Test-Path $FableDir) {
        Remove-Item -Recurse -Force $FableDir -Confirm:$false
        Write-Host "  removed core   $FableDir"
    }
    Remove-MarkerBlock -Path $ClaudeMdPath
    Write-Host "  cleaned CLAUDE.md import block"

    # Remove skills/agents dirs only if we left them empty (they may hold the
    # user's own skills and agents).
    foreach ($dir in @($SkillsDir, $AgentsDir)) {
        if ((Test-Path $dir) -and ((Get-ChildItem -Force $dir | Measure-Object).Count -eq 0)) {
            Remove-Item -Force $dir -Confirm:$false
        }
    }

    Write-Host "Done. Fableathome removed." -ForegroundColor Green
    return
}

Write-Host "Installing Fableathome ($Scope scope) -> $ClaudeDir" -ForegroundColor Cyan

# 1. Core
New-Item -ItemType Directory -Force $FableDir | Out-Null
Copy-Item (Join-Path $SourceRoot 'core\fable-core.md') (Join-Path $FableDir 'fable-core.md') -Force
Write-Host "  core    fable/fable-core.md"

# 2. Skills
foreach ($name in $SkillNames) {
    $dest = Join-Path $SkillsDir $name
    New-Item -ItemType Directory -Force $dest | Out-Null
    Copy-Item (Join-Path $SourceRoot "skills\$name\SKILL.md") (Join-Path $dest 'SKILL.md') -Force
    Write-Host "  skill   /$name"
}

# 3. Agents
New-Item -ItemType Directory -Force $AgentsDir | Out-Null
foreach ($file in $AgentFiles) {
    Copy-Item (Join-Path $SourceRoot "agents\$file") (Join-Path $AgentsDir $file) -Force
    Write-Host "  agent   $($file -replace '\.md$', '')"
}

# 4. Wire the core into CLAUDE.md (idempotent: replace our block if present).
Remove-MarkerBlock -Path $ClaudeMdPath
$block = @(
    $MarkerStart
    '# Fableathome harness - managed block, do not edit by hand.'
    '# Re-run install.ps1 to update, or install.ps1 -Uninstall to remove.'
    $ImportLine
    $MarkerEnd
) -join "`r`n"

if (Test-Path $ClaudeMdPath) {
    $existing = (Get-Content $ClaudeMdPath -Raw).TrimEnd()
    if ($existing.Length -gt 0) {
        Set-Content -Path $ClaudeMdPath -Value ($existing + "`r`n`r`n" + $block) -Encoding utf8
    } else {
        Set-Content -Path $ClaudeMdPath -Value $block -Encoding utf8
    }
} else {
    New-Item -ItemType Directory -Force (Split-Path $ClaudeMdPath) | Out-Null
    Set-Content -Path $ClaudeMdPath -Value $block -Encoding utf8
}
Write-Host "  wired   $ClaudeMdPath ($ImportLine)"

Write-Host "Done. New Claude Code sessions now run under the Fable Protocol." -ForegroundColor Green
Write-Host "Try: /deepthink, /verify-loop, /checkpoint, /council" -ForegroundColor Green
