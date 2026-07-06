# Stop hook: the verification gate. If code files were edited this session
# and nothing was run afterward, block the stop ONCE with a demand to verify
# (or explicitly report unverified). Block-once is guaranteed two ways:
# stop_hook_active from Claude Code, plus our own blocked_once flag - so the
# gate can never loop a session, regardless of harness semantics.
try {
    . (Join-Path $PSScriptRoot 'fable-common.ps1')
    $evt = Read-HookEvent
    if ($null -eq $evt -or -not $evt.session_id) { exit 0 }

    # Already continuing from a previous block: always allow.
    if ($evt.stop_hook_active) { exit 0 }

    $state = Read-FableState -SessionId $evt.session_id
    if ($null -eq $state) { exit 0 }
    if ($state.blocked_once) { exit 0 }
    if (-not $state.last_edit -or $state.last_edit -eq 0) { exit 0 }
    if ($state.last_bash -ge $state.last_edit) { exit 0 }

    # Edits happened, nothing ran afterward, first offense: block.
    $state.blocked_once = $true
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
