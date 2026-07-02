# UserPromptSubmit hook: heuristic Deep-tier detector.
# Plain stdout is injected into context alongside the user's prompt.
try {
    . (Join-Path $PSScriptRoot 'fable-common.ps1')
    $evt = Read-HookEvent
    if ($null -eq $evt -or -not $evt.prompt) { exit 0 }

    $p = [string]$evt.prompt

    # Already invoking a skill or a one-liner: stay out of the way.
    if ($p -match '^\s*/' -or $p.Length -lt 40) { exit 0 }

    $deepSignals = '(?i)\b(root ?cause|why (is|does|do|would|did)|debug|diagnos\w*|' +
                   'flaky|intermittent\w*|race condition|deadlock|crash\w*|corrupt\w*|' +
                   'architect\w*|redesign|refactor\w*|migrat\w*|rewrite|overhaul|' +
                   'should (we|i) use|trade-?offs?)\b'

    if ($p -match $deepSignals) {
        Write-Output 'Fable Protocol: this prompt contains Deep-tier signals (root-cause, design, or cross-cutting work). Resolve any unstated requirements with the user first, then run /deepthink before modifying code; for decisions with material trade-offs, use /council.'
    }
    exit 0
} catch {
    exit 0
}
