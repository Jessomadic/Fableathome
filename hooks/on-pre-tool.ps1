# PreToolUse hook (matcher: Bash): the walk-away safety net. Blocks
# catastrophic, irreversible commands before they run and points the model at
# the fable-warden for a blast-radius review. Fail-open on infrastructure
# errors (a hook glitch must never brick the session), but deny on a confirmed
# dangerous-pattern match.
try {
    . (Join-Path $PSScriptRoot 'fable-common.ps1')
    $evt = Read-HookEvent
    if ($null -eq $evt) { exit 0 }
    if ($evt.tool_name -ne 'Bash') { exit 0 }

    $cmd = ''
    if ($evt.tool_input -and $evt.tool_input.command) { $cmd = [string]$evt.tool_input.command }
    if ([string]::IsNullOrWhiteSpace($cmd)) { exit 0 }

    $danger = Get-FableDangerVerdict -Command $cmd
    if ($null -eq $danger) { exit 0 }

    $reason = "Fable safety gate blocked this command - category: $($danger.Category). " +
              "$($danger.Detail) The action cannot be cheaply reversed and the session may be unattended. " +
              "Do not retry it unchanged. Instead: (1) consult the fable-warden subagent to review the blast " +
              "radius, recovery path, and whether the evidence supports this specific action; (2) use a " +
              "reversible alternative (git stash rather than reset --hard, --force-with-lease rather than " +
              "--force, back up or soft-delete before removing, a scoped path rather than a broad one). " +
              "If the action is required, safe, and authorized, ask the user to run it directly, or the user " +
              "can temporarily disable the fable PreToolUse hook in settings.json."

    @{
        hookSpecificOutput = @{
            hookEventName            = 'PreToolUse'
            permissionDecision       = 'deny'
            permissionDecisionReason = $reason
        }
    } | ConvertTo-Json -Compress -Depth 6 | Write-Output
    exit 0
} catch {
    exit 0
}
