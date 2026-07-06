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
$SkillNames  = @('deepthink', 'verify-loop', 'checkpoint', 'council',
                 'swarm', 'build', 'postmortem',
                 'debug', 'refactor', 'test', 'security-review')
$AgentFiles  = @('fable-planner.md', 'fable-critic.md', 'fable-explorer.md',
                 'fable-builder.md', 'fable-verifier.md', 'fable-historian.md',
                 'fable-warden.md')
$HookScripts = @('fable-common.ps1', 'on-session-start.ps1', 'on-prompt-submit.ps1',
                 'on-pre-tool.ps1', 'on-post-tool.ps1', 'on-stop.ps1', 'on-pre-compact.ps1')

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

$FableDir     = Join-Path $ClaudeDir 'fable'
$SkillsDir    = Join-Path $ClaudeDir 'skills'
$AgentsDir    = Join-Path $ClaudeDir 'agents'
$HooksDir     = Join-Path $FableDir 'hooks'
$SettingsPath = Join-Path $ClaudeDir 'settings.json'

# Hook script paths as they appear in settings.json. Project scope uses the
# ${CLAUDE_PROJECT_DIR} substitution so settings stay machine-portable.
if ($Scope -eq 'global') {
    $HookPathPrefix = $HooksDir
} else {
    $HookPathPrefix = '${CLAUDE_PROJECT_DIR}/.claude/fable/hooks'
}

function New-FableHookDef {
    param([string]$ScriptName, [int]$TimeoutSec)
    $scriptPath = if ($Scope -eq 'global') { Join-Path $HookPathPrefix $ScriptName } else { "$HookPathPrefix/$ScriptName" }
    return [pscustomobject]@{
        type    = 'command'
        command = 'powershell.exe'
        args    = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath)
        timeout = $TimeoutSec
    }
}

function Get-FableHookWiring {
    # Event name -> matcher-group entries we own. Matcher only where the
    # event supports tool matching.
    return @(
        [pscustomobject]@{ Event = 'SessionStart';     Group = [pscustomobject]@{ hooks = @(New-FableHookDef 'on-session-start.ps1' 15) } }
        [pscustomobject]@{ Event = 'UserPromptSubmit'; Group = [pscustomobject]@{ hooks = @(New-FableHookDef 'on-prompt-submit.ps1' 10) } }
        [pscustomobject]@{ Event = 'PreToolUse';       Group = [pscustomobject]@{ matcher = 'Bash'; hooks = @(New-FableHookDef 'on-pre-tool.ps1' 10) } }
        [pscustomobject]@{ Event = 'PostToolUse';      Group = [pscustomobject]@{ matcher = 'Edit|Write|NotebookEdit|Bash'; hooks = @(New-FableHookDef 'on-post-tool.ps1' 10) } }
        [pscustomobject]@{ Event = 'Stop';             Group = [pscustomobject]@{ hooks = @(New-FableHookDef 'on-stop.ps1' 10) } }
        [pscustomobject]@{ Event = 'PreCompact';       Group = [pscustomobject]@{ hooks = @(New-FableHookDef 'on-pre-compact.ps1' 10) } }
    )
}

function Test-FableHookGroup {
    # True if a settings.json matcher-group was installed by us (identified
    # by the fable hooks path inside its command/args).
    param($Group)
    if ($null -eq $Group -or $null -eq $Group.hooks) { return $false }
    foreach ($h in @($Group.hooks)) {
        $joined = ''
        if ($h.PSObject.Properties.Name -contains 'args' -and $h.args) { $joined = (@($h.args) -join ' ') }
        if ($h.PSObject.Properties.Name -contains 'command' -and $h.command) { $joined = $joined + ' ' + $h.command }
        if ($joined -match 'fable[\\/]+hooks[\\/]+') { return $true }
    }
    return $false
}

function Read-Settings {
    if (Test-Path $SettingsPath) {
        try {
            $parsed = Get-Content $SettingsPath -Raw | ConvertFrom-Json
            if ($null -ne $parsed) { return $parsed }
        } catch {
            throw "Could not parse $SettingsPath - fix or remove it, then re-run. (No changes were made.)"
        }
    }
    return [pscustomobject]@{}
}

function Save-Settings {
    param($Settings)
    New-Item -ItemType Directory -Force (Split-Path $SettingsPath) | Out-Null
    $Settings | ConvertTo-Json -Depth 32 | Set-Content -Path $SettingsPath -Encoding utf8
}

function Remove-FableHooksFromSettings {
    param($Settings)
    if (-not ($Settings.PSObject.Properties.Name -contains 'hooks') -or $null -eq $Settings.hooks) { return $Settings }
    foreach ($eventName in @($Settings.hooks.PSObject.Properties.Name)) {
        $kept = @(@($Settings.hooks.$eventName) | Where-Object { -not (Test-FableHookGroup $_) })
        if ($kept.Count -eq 0) {
            $Settings.hooks.PSObject.Properties.Remove($eventName)
        } else {
            $Settings.hooks.$eventName = $kept
        }
    }
    if (@($Settings.hooks.PSObject.Properties).Count -eq 0) {
        $Settings.PSObject.Properties.Remove('hooks')
    }
    return $Settings
}

function Add-FableHooksToSettings {
    param($Settings)
    if (-not ($Settings.PSObject.Properties.Name -contains 'hooks') -or $null -eq $Settings.hooks) {
        $Settings | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    foreach ($wire in Get-FableHookWiring) {
        $existing = @()
        if ($Settings.hooks.PSObject.Properties.Name -contains $wire.Event -and $null -ne $Settings.hooks.($wire.Event)) {
            $existing = @($Settings.hooks.($wire.Event))
        }
        $merged = @($existing + $wire.Group)
        if ($Settings.hooks.PSObject.Properties.Name -contains $wire.Event) {
            $Settings.hooks.($wire.Event) = $merged
        } else {
            $Settings.hooks | Add-Member -NotePropertyName $wire.Event -NotePropertyValue $merged
        }
    }
    return $Settings
}

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
        Write-Host "  removed core   $FableDir  (includes hooks)"
    }
    Remove-MarkerBlock -Path $ClaudeMdPath
    Write-Host "  cleaned CLAUDE.md import block"

    if (Test-Path $SettingsPath) {
        $settings = Read-Settings
        $settings = Remove-FableHooksFromSettings -Settings $settings
        Save-Settings -Settings $settings
        Write-Host "  cleaned settings.json hook entries"
    }

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

# 4. Hooks: scripts + settings.json wiring (idempotent: our entries are
#    removed and re-added; user entries are untouched; one-time backup).
New-Item -ItemType Directory -Force $HooksDir | Out-Null
foreach ($file in $HookScripts) {
    Copy-Item (Join-Path $SourceRoot "hooks\$file") (Join-Path $HooksDir $file) -Force
}
Write-Host "  hooks   $($HookScripts.Count) scripts -> fable/hooks/"

$backupPath = "$SettingsPath.fable-backup"
if ((Test-Path $SettingsPath) -and -not (Test-Path $backupPath)) {
    Copy-Item $SettingsPath $backupPath
    Write-Host "  backup  $backupPath (one-time)"
}
$settings = Read-Settings
$settings = Remove-FableHooksFromSettings -Settings $settings
$settings = Add-FableHooksToSettings -Settings $settings
Save-Settings -Settings $settings
Write-Host "  wired   settings.json (SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop, PreCompact)"

# 5. Wire the core into CLAUDE.md (idempotent: replace our block if present).
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
