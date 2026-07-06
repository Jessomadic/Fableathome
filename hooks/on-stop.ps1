# Stop hook: the verification gate. If code files were edited and nothing was
# run afterward, block the stop with a demand to verify (or explicitly report
# unverified). Blocks once PER UNVERIFIED EDIT-BATCH: we record the timestamp of
# the edit we blocked for (blocked_edit); the same batch is never re-blocked (so
# the gate can never loop), but a NEWER unverified edit re-arms it. stop_hook_active
# from Claude Code is the belt-and-suspenders immediate-loop guard.
try {
    . (Join-Path $PSScriptRoot 'fable-common.ps1')
    $evt = Read-HookEvent
    if ($null -eq $evt -or -not $evt.session_id) { exit 0 }

    # Already continuing from a previous block: always allow.
    if ($evt.stop_hook_active) { exit 0 }

    $state = Read-FableState -SessionId $evt.session_id
    if ($null -eq $state) { exit 0 }
    if (-not $state.last_edit -or $state.last_edit -eq 0) { exit 0 }
    if ($state.last_bash -ge $state.last_edit) { exit 0 }

    # Unverified edits exist. Block once per edit-batch: if we already blocked for
    # this exact edit timestamp, let the stop through (no loop). A newer edit
    # (later last_edit) re-arms the gate.
    $blockedEdit = if ($state.blocked_edit) { [long]$state.blocked_edit } else { 0 }
    if ($blockedEdit -ge [long]$state.last_edit) { exit 0 }

    # Edits happened, nothing ran afterward, this batch not yet gated: block.
    $state | Add-Member -NotePropertyName blocked_edit -NotePropertyValue ([long]$state.last_edit) -Force
    Write-FableState -SessionId $evt.session_id -State $state

    $reason = 'Fable verification gate: code files were modified this session but nothing was run afterward. ' +
              'Before stopping, either (a) exercise the changed behavior end-to-end (/verify-loop: run the code, ' +
              'the tests, the real execution path) and report the evidence, or (b) state to the user that the ' +
              'change is UNVERIFIED and why verification was not possible. ' +
              'Do NOT fabricate output to satisfy this gate: do not write an execution transcript, test result, ' +
              'or program output that you did not actually produce by running the code. If you cannot run it, ' +
              'option (b) is the correct answer. Most code is runnable here — on Windows, execute via ' +
              '"powershell.exe -NoProfile -Command ...". Then stopping is permitted.'
    @{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress | Write-Output
    exit 0
} catch {
    exit 0
}
