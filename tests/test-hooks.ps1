# Hook I/O tests: pipe crafted stdin JSON into each hook script and assert on
# output / exit codes. Covers the PreToolUse safety gate end-to-end and the
# stop-gate's read-only hardening.
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$hooks = Join-Path $repo 'hooks'
$sid = "hooktest-$(Get-Random)"
$statePath = Join-Path $env:TEMP "fableathome\state-$sid.json"
$fails = 0

function Invoke-Hook {
    param([string]$Script, [string]$Json)
    $out = $Json | powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $hooks $Script)
    return @{ out = ($out -join "`n"); code = $LASTEXITCODE }
}
function Assert {
    param([bool]$Cond, [string]$Name)
    if ($Cond) { Write-Host "PASS  $Name" } else { Write-Host "FAIL  $Name" -ForegroundColor Red; $script:fails++ }
}

# --- PreToolUse safety gate ---
$r = Invoke-Hook 'on-pre-tool.ps1' (@{ tool_name = 'Bash'; tool_input = @{ command = 'rm -rf /' } } | ConvertTo-Json -Compress)
Assert ($r.out -match '"permissionDecision":"deny"') 'pre-tool denies rm -rf /'
Assert ($r.out -match 'fable-warden') 'pre-tool deny points at the warden'
Assert ($r.code -eq 0) 'pre-tool exits 0 (JSON contract, not exit 2)'

$r = Invoke-Hook 'on-pre-tool.ps1' (@{ tool_name = 'Bash'; tool_input = @{ command = 'git push --force origin main' } } | ConvertTo-Json -Compress)
Assert ($r.out -match '"permissionDecision":"deny"') 'pre-tool denies git force-push'

$r = Invoke-Hook 'on-pre-tool.ps1' (@{ tool_name = 'Bash'; tool_input = @{ command = 'npm test' } } | ConvertTo-Json -Compress)
Assert ([string]::IsNullOrWhiteSpace($r.out)) 'pre-tool allows npm test (no output)'

$r = Invoke-Hook 'on-pre-tool.ps1' (@{ tool_name = 'Bash'; tool_input = @{ command = 'rm -rf node_modules' } } | ConvertTo-Json -Compress)
Assert ([string]::IsNullOrWhiteSpace($r.out)) 'pre-tool allows rm -rf node_modules'

$r = Invoke-Hook 'on-pre-tool.ps1' (@{ tool_name = 'Edit'; tool_input = @{ file_path = 'x.ps1' } } | ConvertTo-Json -Compress)
Assert ([string]::IsNullOrWhiteSpace($r.out)) 'pre-tool ignores non-Bash tools'

# --- SessionStart: clarify-at-start on a fresh project, memory load otherwise ---
$proj = Join-Path $env:TEMP "fableproj-$sid"
New-Item -ItemType Directory -Force $proj | Out-Null
$r = Invoke-Hook 'on-session-start.ps1' (@{ session_id = $sid; cwd = $proj } | ConvertTo-Json -Compress)
Assert ($r.out -match 'clarifying questions') 'session-start prompts for clarifying questions on a new project'
New-Item -ItemType Directory -Force (Join-Path $proj '.fable') | Out-Null
Set-Content (Join-Path $proj '.fable\CHECKPOINT.md') "# Checkpoint`nGoal: MARKER-42" -Encoding utf8
$r = Invoke-Hook 'on-session-start.ps1' (@{ session_id = $sid; cwd = $proj } | ConvertTo-Json -Compress)
Assert ($r.out -match 'MARKER-42') 'session-start loads checkpoint when present'
Assert ($r.out -notmatch 'clarifying questions') 'session-start does not re-prompt clarify when a checkpoint exists'
Remove-Item -Recurse -Force $proj -Confirm:$false

# --- stop-gate hardening: read-only command does NOT satisfy verification ---
Remove-Item $statePath -Force -ErrorAction SilentlyContinue
Invoke-Hook 'on-post-tool.ps1' (@{ session_id = $sid; tool_name = 'Edit'; tool_input = @{ file_path = 'D:\x\app.ps1' } } | ConvertTo-Json -Compress) | Out-Null
Invoke-Hook 'on-post-tool.ps1' (@{ session_id = $sid; tool_name = 'Bash'; tool_input = @{ command = 'ls -la' } } | ConvertTo-Json -Compress) | Out-Null
$r = Invoke-Hook 'on-stop.ps1' (@{ session_id = $sid; stop_hook_active = $false } | ConvertTo-Json -Compress)
Assert ($r.out -match '"decision":"block"') 'stop-gate still fires after edit + only ls (ls does not count)'

# real verification (a test run) DOES satisfy it
Remove-Item $statePath -Force -ErrorAction SilentlyContinue
Invoke-Hook 'on-post-tool.ps1' (@{ session_id = $sid; tool_name = 'Edit'; tool_input = @{ file_path = 'D:\x\app.ps1' } } | ConvertTo-Json -Compress) | Out-Null
Invoke-Hook 'on-post-tool.ps1' (@{ session_id = $sid; tool_name = 'Bash'; tool_input = @{ command = 'npm test' } } | ConvertTo-Json -Compress) | Out-Null
$r = Invoke-Hook 'on-stop.ps1' (@{ session_id = $sid; stop_hook_active = $false } | ConvertTo-Json -Compress)
Assert ([string]::IsNullOrWhiteSpace($r.out)) 'stop-gate satisfied after edit + real test run'

# --- fail-open on garbage stdin (every hook) ---
foreach ($h in @('on-session-start.ps1','on-prompt-submit.ps1','on-pre-tool.ps1','on-post-tool.ps1','on-stop.ps1','on-pre-compact.ps1')) {
    $r = Invoke-Hook $h 'not json {'
    Assert ($r.code -eq 0) "fail-open: $h on garbage stdin"
}

if (Test-Path $statePath) { Remove-Item $statePath -Force -ErrorAction SilentlyContinue }
Write-Host ''
if ($fails -eq 0) { Write-Host 'HOOKS: ALL PASSED' -ForegroundColor Green } else { Write-Host "HOOKS: $fails FAILED" -ForegroundColor Red; exit 1 }
