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
