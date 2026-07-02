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
        Write-Output '<fable-memory source=".fable/CHECKPOINT.md" note="Loaded by Fableathome. Snapshot from a previous session; confirm facts are current before relying on them.">'
        Get-Content $checkpoint
        Write-Output '</fable-memory>'
        $emitted = $true
    }
    if (Test-Path $lessons) {
        Write-Output '<fable-memory source=".fable/LESSONS.md" note="Lessons from previous sessions. Apply without being prompted (last 80 lines).">'
        Get-Content $lessons -Tail 80
        Write-Output '</fable-memory>'
        $emitted = $true
    }
    if ($emitted) {
        Write-Output 'Fable Protocol: memory loaded above. Confirm the checkpoint "Next" list with the user before starting new work.'
    } else {
        # No prior state: this is a new project or first session. Front-load
        # requirement clarification per Fable Protocol section 2.
        Write-Output 'Fable Protocol: no prior checkpoint found (new project or first session). Before planning or modifying code, identify every ambiguity and unstated requirement, and ask the user a batched set of clarifying questions covering scope and goal, constraints (language, runtime, versions, dependencies), interfaces and data formats, acceptance criteria, and target environment. Ask as many as the task warrants in one round rather than discovering gaps during execution. Skip questions whose answers are already specified.'
    }
    exit 0
} catch {
    exit 0
}
