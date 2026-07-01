# PostToolUse hook (matcher: Edit|Write|NotebookEdit|Bash): maintain the
# session's edit/verify ledger for the stop gate.
try {
    . (Join-Path $PSScriptRoot 'fable-common.ps1')
    $evt = Read-HookEvent
    if ($null -eq $evt -or -not $evt.session_id) { exit 0 }

    $state = Read-FableState -SessionId $evt.session_id
    if ($null -eq $state) {
        $state = [pscustomobject]@{ last_edit = 0; last_bash = 0; blocked_once = $false }
    }

    if ($evt.tool_name -eq 'Bash') {
        $state.last_bash = Get-UnixNow
    } else {
        # Edit / Write / NotebookEdit. Skip files with no runtime surface:
        # docs, plain text, and the harness's own memory/config trees.
        $filePath = ''
        if ($evt.tool_input -and $evt.tool_input.file_path) {
            $filePath = [string]$evt.tool_input.file_path
        }
        $normalized = $filePath -replace '\\', '/'
        $skip = ($normalized -match '(?i)\.(md|markdown|txt|rst)$') -or
                ($normalized -match '(?i)/(\.fable|\.claude)/')
        if (-not $skip) {
            $state.last_edit = Get-UnixNow
        }
    }

    Write-FableState -SessionId $evt.session_id -State $state
    exit 0
} catch {
    exit 0
}
