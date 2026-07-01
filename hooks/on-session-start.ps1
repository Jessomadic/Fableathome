# SessionStart hook: auto-load project memory and reset the session state.
# Plain stdout from this hook is injected into Claude's context.
try {
    . (Join-Path $PSScriptRoot 'fable-common.ps1')
    $evt = Read-HookEvent
    if ($null -eq $evt) { exit 0 }

    # Fresh session -> fresh edit/verify ledger for the stop gate.
    if ($evt.session_id) {
        $statePath = Get-FableStatePath -SessionId $evt.session_id
        if (Test-Path $statePath) { Remove-Item -Force $statePath -Confirm:$false }
    }

    $proj = $evt.cwd
    if (-not $proj) { exit 0 }

    $checkpoint = Join-Path $proj '.fable\CHECKPOINT.md'
    $lessons    = Join-Path $proj '.fable\LESSONS.md'
    $emitted    = $false

    if (Test-Path $checkpoint) {
        Write-Output '<fable-memory source=".fable/CHECKPOINT.md" note="auto-loaded by Fableathome; snapshot from a previous session - verify facts still hold before relying on them">'
        Get-Content $checkpoint
        Write-Output '</fable-memory>'
        $emitted = $true
    }
    if (Test-Path $lessons) {
        Write-Output '<fable-memory source=".fable/LESSONS.md" note="lessons from previous sessions - standing orders, apply without being asked (last 80 lines)">'
        Get-Content $lessons -Tail 80
        Write-Output '</fable-memory>'
        $emitted = $true
    }
    if ($emitted) {
        Write-Output 'Fable Protocol: memory auto-loaded above. Acknowledge the checkpoint "Next" list to the user before starting new work.'
    }
    exit 0
} catch {
    exit 0
}
