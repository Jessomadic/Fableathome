# PreCompact hook: best-effort instruction to the compactor to preserve the
# working memory that matters. (additionalContext on PreCompact is not
# firmly documented; if the harness ignores it, this is harmless - fail-open
# by design.)
try {
    $null = [Console]::In.ReadToEnd()
    $ctx = 'Compaction instructions from the Fable Protocol: preserve VERBATIM in the summary - ' +
           '(1) the overall goal and success criteria, (2) what is done vs in-progress vs next, ' +
           '(3) every decision made and its reason, (4) gotchas and lessons discovered, ' +
           '(5) any UNVERIFIED claims and blocked items. If .fable/CHECKPOINT.md exists, remind ' +
           'the continuing session to run /checkpoint to persist state after compaction.'
    @{ additionalContext = $ctx } | ConvertTo-Json -Compress | Write-Output
    exit 0
} catch {
    exit 0
}
