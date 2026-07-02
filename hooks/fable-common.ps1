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
    # Home / profile / temp variables, including a subpath under them.
    if ($lower -match '^\$env:(userprofile|homepath|home)([\\/]|$)') { return $true }
    if ($lower -match '^\$\{?home\}?([\\/]|$)') { return $true }
    if ($lower -match '^%(userprofile|homepath|home)%([\\/]|$)') { return $true }
    if ($lower -in @('$pwd', '$env:temp', '${pwd}')) { return $true }
    # An unquoted variable used as a path: empty expansion turns "$X/" into "/".
    if ($t -match '^\$\{?\w+\}?(/|$)') { return $true }
    if ($t -match '^%\w+%(\\|$)') { return $true }
    # Unix root and system directories.
    if ($lower -match '^/(etc|usr|var|bin|sbin|lib|lib64|sys|proc|boot|root|home|opt|dev|srv|run|system|applications|library)(/|$)') { return $true }
    if ($lower -eq '/' -or $lower -match '^/\s*$') { return $true }
    # Home-relative expansions.
    if ($t -match '^~($|/)') { return $true }
    # Windows drive roots and system directories (either slash), plus UNC.
    if ($lower -match '^[a-z]:[\\/]?$') { return $true }
    if ($lower -match '^[a-z]:[\\/](windows|users|program files|program files \(x86\)|programdata|system32)([\\/]|$)') { return $true }
    if ($t -match '^\\\\') { return $true }
    return $false
}

function Test-FableDeleteSegment {
    # $Segment is ONE command (leading sudo already stripped). Returns $true if
    # it is a recursive/forced delete aimed at a catastrophic target. Scoped to
    # a single segment so a critical path mentioned elsewhere on the command
    # line (a quoted string, an unrelated subcommand) does not trigger it.
    param([string]$Segment)
    $s = $Segment
    $verbs = @('rm', 'remove-item', 'ri', 'del', 'erase', 'rd', 'rmdir', 'unlink')

    $isUnixRm = $s -match '(?i)^rm(\s|$)'
    $isPwshRm = $s -match '(?i)^(remove-item|ri)(\s|$)'
    $isWinRd  = ($s -match '(?i)^(rd|rmdir)\s+/s') -or ($s -match '(?i)^del\s+/[a-z]*s')
    if (-not ($isUnixRm -or $isPwshRm -or $isWinRd)) { return $false }

    if ($isWinRd) {
        # rd /s and del /s are recursive by definition.
        $tokens = @($s -split '\s+' | Where-Object { $_ -and ($_ -notmatch '^[-/]') -and ($verbs -notcontains $_.ToLower()) })
        foreach ($tok in $tokens) { if (Test-FableCatastrophicPath $tok) { return $true } }
        return $false
    }

    $hasRecursive = $s -match '(?i)(-{1,2}[a-z]*r[a-z]*\b|--recursive|\s-r\b|\s-R\b|-Recurse\b)'
    $hasForce     = $s -match '(?i)(-{1,2}[a-z]*f[a-z]*\b|--force|\s-f\b|-Force\b)'
    # PowerShell Remove-Item deletes trees with -Recurse alone; unix rm needs
    # both recursive and force.
    $recursiveDelete = if ($isPwshRm) { $hasRecursive } else { $hasRecursive -and $hasForce }
    if (-not $recursiveDelete) { return $false }

    $tokens = @($s -split '\s+' | Where-Object { $_ -and ($_ -notmatch '^-') -and ($verbs -notcontains $_.ToLower()) })
    foreach ($tok in $tokens) { if (Test-FableCatastrophicPath $tok) { return $true } }
    return $false
}

function Get-FableDangerVerdict {
    # Returns $null if the command is safe, or {Category, Detail} if it is a
    # catastrophic / irreversible action that should be gated. Command-anchored
    # checks run per segment so a dangerous pattern inside a quoted string or an
    # unrelated subcommand (e.g. a commit message) does not match.
    param([string]$Command)
    if ([string]::IsNullOrWhiteSpace($Command)) { return $null }
    $c = $Command

    # Whole-command patterns that intentionally span separators.
    if ($c -match '(?i)\b(curl|wget|iwr|invoke-webrequest)\b[^\n]*\|\s*(sudo\s+)?(sh|bash|zsh|fish|python[0-9.]*|perl|ruby|node|powershell|pwsh)\b') {
        return [pscustomobject]@{ Category = 'pipe remote script to a shell'; Detail = 'Executing downloaded content unseen runs arbitrary code from the network.' }
    }
    if ($c -match ':\s*\(\s*\)\s*\{\s*:\s*\|\s*:' -or $c -match '\(\)\{\s*:\|:&\s*\}') {
        return [pscustomobject]@{ Category = 'fork bomb'; Detail = 'This pattern spawns processes until the machine is unusable.' }
    }

    # Per-segment, command-anchored checks.
    foreach ($seg in ($c -split '[;&|]+')) {
        $s = $seg.Trim()
        if ($s -eq '') { continue }
        $s = ($s -replace '(?i)^sudo\s+', '').Trim()
        if ($s -eq '') { continue }

        if (Test-FableDeleteSegment $s) {
            return [pscustomobject]@{ Category = 'recursive delete of a critical path'; Detail = 'Recursively deleting root, home, the current directory, a system path, or an unquoted variable target destroys data with no recovery.' }
        }
        if ($s -match '(?i)^git\s+push\b' -and ($s -match '(?i)--force(?!-with-lease)' -or $s -match '(?i)(\s|^)-f(\s|$)')) {
            return [pscustomobject]@{ Category = 'git force-push'; Detail = 'A force-push can overwrite remote history and other people''s work irreversibly. Prefer --force-with-lease.' }
        }
        if ($s -match '(?i)^git\s+reset\b.*--hard') {
            return [pscustomobject]@{ Category = 'git reset --hard'; Detail = 'Discards all uncommitted work with no undo. Prefer git stash.' }
        }
        if ($s -match '(?i)^git\s+clean\b.*\s-[a-z]*f') {
            return [pscustomobject]@{ Category = 'git clean -f'; Detail = 'Permanently deletes untracked files, including ones never committed.' }
        }
        if ($s -match '(?i)^dd\b.*\bof=\s*/dev/') {
            return [pscustomobject]@{ Category = 'dd to a device'; Detail = 'Writing dd output to a block device destroys the disk''s contents.' }
        }
        if ($s -match '(?i)^mkfs(\.\w+)?\b' -or $s -match '(?i)>\s*/dev/(sd|nvme|disk|hd)') {
            return [pscustomobject]@{ Category = 'filesystem/disk overwrite'; Detail = 'Formatting or writing raw to a disk device is irreversible.' }
        }
        if ($s -match '(?i)^format\s+[a-z]:') {
            return [pscustomobject]@{ Category = 'drive format'; Detail = 'Formatting a drive erases everything on it.' }
        }
        if ($s -match '(?i)^(shutdown|reboot|halt|poweroff)\b' -or
            $s -match '(?i)^init\s+[06]\b' -or
            $s -match '(?i)^(Stop-Computer|Restart-Computer)\b') {
            return [pscustomobject]@{ Category = 'shutdown/reboot'; Detail = 'Changing the machine power state interrupts everything running.' }
        }
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
