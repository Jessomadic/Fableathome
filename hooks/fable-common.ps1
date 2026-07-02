# Shared helpers for Fableathome hooks. Dot-sourced by each hook script.
# Design rule: hooks FAIL OPEN. Any error means "do nothing", never "break
# the session". Callers wrap everything in try/catch and exit 0 on failure.

function Read-HookEvent {
    # Reads the hook's stdin JSON. Returns $null on any failure.
    try {
        $raw = [Console]::In.ReadToEnd()
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        return $raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Get-FableStatePath {
    param([string]$SessionId)
    $dir = Join-Path $env:TEMP 'fableathome'
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force $dir | Out-Null
    }
    $safeId = ($SessionId -replace '[^\w\-]', '_')
    return Join-Path $dir "state-$safeId.json"
}

function Read-FableState {
    param([string]$SessionId)
    $path = Get-FableStatePath -SessionId $SessionId
    if (Test-Path $path) {
        try { return Get-Content $path -Raw | ConvertFrom-Json } catch { return $null }
    }
    return $null
}

function Write-FableState {
    param([string]$SessionId, $State)
    $path = Get-FableStatePath -SessionId $SessionId
    $State | ConvertTo-Json -Compress | Set-Content -Path $path -Encoding utf8
}

function Get-UnixNow {
    return [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
}

# --- Safety: dangerous-command detection (used by the PreToolUse hook) ---
# Design: catch catastrophic, IRREVERSIBLE actions while keeping common,
# safe operations (rm -rf node_modules, git push, git stash) flowing. The
# differentiator for deletes is the TARGET, not the flags.

function Test-FableCatastrophicPath {
    # True if a delete aimed at this path would be a disaster (root, home,
    # cwd wipe, system dirs, or a variable that could expand to empty -> "/").
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return $false }
    $t = $Raw.Trim().Trim('"', "'")
    if ($t -eq '') { return $false }
    $lower = $t.ToLower()

    if ($t -in @('/', '~', '.', '..', '*', './*', '~/', '/*', '.\*', '.\')) { return $true }
    if ($lower -in @('$home', '${home}', '$env:userprofile', '%userprofile%', '$home/', '$env:homepath', '$pwd', '$env:temp')) { return $true }
    # An unquoted variable used as a path: empty expansion turns "$X/" into "/".
    if ($t -match '^\$\{?\w+\}?(/|$)') { return $true }
    if ($t -match '^%\w+%(\\|$)') { return $true }
    # Unix root and system directories.
    if ($lower -match '^/(etc|usr|var|bin|sbin|lib|lib64|sys|proc|boot|root|home|opt|dev|srv|run|system|applications|library)(/|$)') { return $true }
    if ($lower -eq '/' -or $lower -match '^/\s*$') { return $true }
    # Home-relative expansions.
    if ($t -match '^~($|/)') { return $true }
    # Windows drive roots and system directories, plus UNC paths.
    if ($lower -match '^[a-z]:\\?$') { return $true }
    if ($lower -match '^[a-z]:\\(windows|users|program files|program files \(x86\)|programdata|system32)(\\|$)') { return $true }
    if ($t -match '^\\\\') { return $true }
    return $false
}

function Test-FableRecursiveDeleteDanger {
    # True if the command is a recursive/forced delete aimed at a catastrophic
    # target. Tokenizes so scoped targets (node_modules, dist) stay allowed.
    param([string]$Command)
    $c = $Command
    $verbs = @('rm', 'sudo', 'remove-item', 'ri', 'del', 'erase', 'rd', 'rmdir', 'unlink')

    $isUnixRm = $c -match '(?i)(^|[\s;&|(])(sudo\s+)?rm(\s|$)'
    $isPwshRm = $c -match '(?i)(^|[\s;&|(])(remove-item|ri)(\s|$)'
    $isWinRd  = $c -match '(?i)(^|[\s;&|(])(rd|rmdir)\s+/s' -or $c -match '(?i)(^|[\s;&|(])del\s+/[a-z]*s'
    if (-not ($isUnixRm -or $isPwshRm -or $isWinRd)) { return $false }

    # rd /s /q <root> and del /s /q <root> are recursive by definition.
    if ($isWinRd) {
        $tokens = @($c -split '\s+' | Where-Object { $_ -and ($_ -notmatch '^[-/]') -and ($verbs -notcontains $_.ToLower()) })
        foreach ($tok in $tokens) { if (Test-FableCatastrophicPath $tok) { return $true } }
        return $false
    }

    $hasRecursive = $c -match '(?i)(-{1,2}[a-z]*r[a-z]*\b|--recursive|\s-r\b|\s-R\b|-Recurse\b)'
    $hasForce     = $c -match '(?i)(-{1,2}[a-z]*f[a-z]*\b|--force|\s-f\b|-Force\b)'
    # PowerShell Remove-Item is treated as dangerous with -Recurse alone
    # (it deletes trees without a force flag); unix rm needs recursive + force.
    $recursiveDelete = if ($isPwshRm) { $hasRecursive } else { $hasRecursive -and $hasForce }
    if (-not $recursiveDelete) { return $false }

    $tokens = @($c -split '\s+' | Where-Object { $_ -and ($_ -notmatch '^-') -and ($verbs -notcontains $_.ToLower()) })
    foreach ($tok in $tokens) { if (Test-FableCatastrophicPath $tok) { return $true } }
    return $false
}

function Get-FableDangerVerdict {
    # Returns $null if the command is safe, or {Category, Detail} if it is a
    # catastrophic / irreversible action that should be gated.
    param([string]$Command)
    if ([string]::IsNullOrWhiteSpace($Command)) { return $null }
    $c = $Command

    if (Test-FableRecursiveDeleteDanger $c) {
        return [pscustomobject]@{ Category = 'recursive delete of a critical path'; Detail = 'Recursively deleting root, home, the current directory, a system path, or an unquoted variable target destroys data with no recovery.' }
    }
    # Force-push (allow the safer --force-with-lease).
    if ($c -match '(?i)\bgit\s+push\b' -and ($c -match '(?i)--force(?!-with-lease)' -or $c -match '(?i)(\s|^)-f(\s|$)')) {
        return [pscustomobject]@{ Category = 'git force-push'; Detail = 'A force-push can overwrite remote history and other people''s work irreversibly. Prefer --force-with-lease.' }
    }
    if ($c -match '(?i)\bgit\s+reset\b[^;&|]*--hard') {
        return [pscustomobject]@{ Category = 'git reset --hard'; Detail = 'Discards all uncommitted work with no undo. Prefer git stash.' }
    }
    if ($c -match '(?i)\bgit\s+clean\b[^;&|]*\s-[a-z]*f') {
        return [pscustomobject]@{ Category = 'git clean -f'; Detail = 'Permanently deletes untracked files, including ones never committed.' }
    }
    if ($c -match '(?i)\bdd\b[^;&|]*\bof=\s*/dev/') {
        return [pscustomobject]@{ Category = 'dd to a device'; Detail = 'Writing dd output to a block device destroys the disk''s contents.' }
    }
    if ($c -match '(?i)\bmkfs(\.\w+)?\b' -or $c -match '(?i)>\s*/dev/(sd|nvme|disk|hd)') {
        return [pscustomobject]@{ Category = 'filesystem/disk overwrite'; Detail = 'Formatting or writing raw to a disk device is irreversible.' }
    }
    if ($c -match '(?i)\bformat\s+[a-z]:') {
        return [pscustomobject]@{ Category = 'drive format'; Detail = 'Formatting a drive erases everything on it.' }
    }
    # Fork bomb.
    if ($c -match ':\s*\(\s*\)\s*\{\s*:\s*\|\s*:' -or $c -match '\(\)\{\s*:\|:&\s*\}') {
        return [pscustomobject]@{ Category = 'fork bomb'; Detail = 'This pattern spawns processes until the machine is unusable.' }
    }
    # Piping a remote script straight into a shell/interpreter.
    if ($c -match '(?i)\b(curl|wget|iwr|invoke-webrequest)\b[^\n]*\|\s*(sudo\s+)?(sh|bash|zsh|fish|python[0-9.]*|perl|ruby|node|powershell|pwsh)\b') {
        return [pscustomobject]@{ Category = 'pipe remote script to a shell'; Detail = 'Executing downloaded content unseen runs arbitrary code from the network.' }
    }
    # System power state. Anchored to command start / after a separator / after
    # sudo so it doesn't trip on "echo shutdown".
    if ($c -match '(?i)(^|[;&|]\s*|\bsudo\s+)(shutdown|reboot|halt|poweroff)\b' -or
        $c -match '(?i)(^|[;&|]\s*)init\s+[06]\b' -or
        $c -match '(?i)\b(Stop-Computer|Restart-Computer)\b') {
        return [pscustomobject]@{ Category = 'shutdown/reboot'; Detail = 'Changing the machine power state interrupts everything running.' }
    }
    return $null
}

function Test-FableTrivialCommand {
    # True if the whole command is a single READ-ONLY inspection invocation
    # (ls, pwd, git status, ...). Such a command must NOT satisfy the stop-gate
    # -- otherwise "run ls to quiet the gate" would count as verification.
    # Conservative: anything with a real second command, a pipe into work, or a
    # test/exec verb returns false so genuine verification still counts.
    param([string]$Command)
    if ([string]::IsNullOrWhiteSpace($Command)) { return $true }
    $t = $Command.Trim()
    if ($t -match '[;&|]|&&') { return $false }
    return ($t -match '(?i)^(ls|dir|pwd|cd|echo|clear|cls|whoami|date|hostname|git\s+(status|log|diff|branch|show|remote)|Get-Location|gl|Get-ChildItem|gci)\b')
}
