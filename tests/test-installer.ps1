# Installer tests: settings.json merge across fixtures, idempotence, and clean
# uninstall. Runs against throwaway scratch projects.
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$installer = Join-Path $repo 'install.ps1'
$root = Join-Path $env:TEMP "fable-inst-$(Get-Random)"
$fails = 0
function Assert { param([bool]$Cond, [string]$Name)
    if ($Cond) { Write-Host "PASS  $Name" } else { Write-Host "FAIL  $Name" -ForegroundColor Red; $script:fails++ } }
function New-Proj { param([string]$Name) $p = Join-Path $root $Name; New-Item -ItemType Directory -Force $p | Out-Null; return $p }

# --- Fixture A: no settings.json ---
$a = New-Proj 'a'
& $installer -Scope project -Target $a | Out-Null
$s = Get-Content (Join-Path $a '.claude\settings.json') -Raw | ConvertFrom-Json
Assert ($null -ne $s.hooks.PreToolUse) 'A: PreToolUse (safety) wired'
Assert (@($s.hooks.PreToolUse)[0].matcher -eq 'Bash') 'A: PreToolUse matcher is Bash'
Assert ($null -ne $s.hooks.SessionStart) 'A: SessionStart wired'
Assert (Test-Path (Join-Path $a '.claude\fable\hooks\on-pre-tool.ps1')) 'A: pre-tool hook script copied'
Assert (Test-Path (Join-Path $a '.claude\fable\hooks\fable-common.ps1')) 'A: shared helper copied'

# idempotence
& $installer -Scope project -Target $a | Out-Null
$s = Get-Content (Join-Path $a '.claude\settings.json') -Raw | ConvertFrom-Json
Assert (@($s.hooks.PreToolUse).Count -eq 1) 'A: reinstall idempotent (1 PreToolUse group)'

& $installer -Scope project -Target $a -Uninstall | Out-Null
$s = Get-Content (Join-Path $a '.claude\settings.json') -Raw | ConvertFrom-Json
Assert (-not ($s.PSObject.Properties.Name -contains 'hooks')) 'A: uninstall removes hooks key'
Assert (-not (Test-Path (Join-Path $a '.claude\fable'))) 'A: uninstall removes scripts'

# --- Fixture B: pre-existing user settings + user hook survive install/uninstall ---
$b = New-Proj 'b'
New-Item -ItemType Directory -Force (Join-Path $b '.claude') | Out-Null
Set-Content (Join-Path $b '.claude\settings.json') '{"permissions":{"allow":["Bash(npm test)"]},"hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo user-stop"}]}],"Notification":[{"hooks":[{"type":"command","command":"echo notify"}]}]}}' -Encoding utf8
& $installer -Scope project -Target $b | Out-Null
$s = Get-Content (Join-Path $b '.claude\settings.json') -Raw | ConvertFrom-Json
Assert ($s.permissions.allow[0] -eq 'Bash(npm test)') 'B: user permissions preserved'
Assert (@($s.hooks.Stop).Count -eq 2) 'B: user Stop hook + fable Stop hook coexist'
Assert (@(@($s.hooks.Stop) | Where-Object { $_.hooks[0].command -eq 'echo user-stop' }).Count -eq 1) 'B: user Stop hook intact'
Assert ($null -ne $s.hooks.Notification) 'B: unrelated user event preserved'
Assert (Test-Path (Join-Path $b '.claude\settings.json.fable-backup')) 'B: one-time backup created'
& $installer -Scope project -Target $b -Uninstall | Out-Null
$s = Get-Content (Join-Path $b '.claude\settings.json') -Raw | ConvertFrom-Json
Assert (@($s.hooks.Stop).Count -eq 1 -and $s.hooks.Stop[0].hooks[0].command -eq 'echo user-stop') 'B: uninstall keeps only user Stop hook'
Assert ($s.permissions.allow[0] -eq 'Bash(npm test)') 'B: uninstall keeps permissions'

# --- Fixture C: PS 5.1 array-shape guard ---
$c = New-Proj 'c'
& $installer -Scope project -Target $c | Out-Null
$raw = Get-Content (Join-Path $c '.claude\settings.json') -Raw
Assert ($raw -match '"PreToolUse":\s*\[') 'C: PreToolUse serialized as array'
Assert ($raw -match '"args":\s*\[') 'C: args serialized as array'

Remove-Item -Recurse -Force $root -Confirm:$false
Write-Host ''
if ($fails -eq 0) { Write-Host 'INSTALLER: ALL PASSED' -ForegroundColor Green } else { Write-Host "INSTALLER: $fails FAILED" -ForegroundColor Red; exit 1 }
