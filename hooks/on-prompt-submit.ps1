# UserPromptSubmit hook: inject Deep-tier and current-sources reminders.
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

    # External / current-information signals: prompt to consult live sources
    # rather than relying on training memory (core section 4).
    $sourceSignals = '(?i)\b(librar\w*|packages?|dependenc\w*|framework|api|sdk|' +
                     'version|latest|current|up-?to-?date|release|changelog|deprecat\w*|' +
                     'install|upgrade|configure|config|documentation|docs|how (do|to)|' +
                     'best practice|standard|spec|cve|vulnerab\w*|npm|pip|cargo|nuget)\b'

    # UI and front-end signals (frameworks and design systems change across
    # versions).
    $uiSignals = '(?i)\b(ui|ux|css|scss|sass|tailwind|component|react|vue|angular|' +
                 'svelte|design system|front-?end|layout|styling|responsive|' +
                 'accessibilit\w*|a11y|wcag|aria|material ui|mui|bootstrap|figma|' +
                 'shadcn|chakra|storybook)\b'

    # Cloud and admin-console signals. These portals are rebranded and
    # reorganized frequently, so training-memory guidance is very often stale.
    $adminSignals = '(?i)\b(entra|intune|azure|gsuite|g suite|google workspace|' +
                    'm365|microsoft 365|office 365|admin cent(er|re)|admin console|' +
                    'okta|graph api|sharepoint|exchange online|conditional access|' +
                    'active directory|azure ad|powershell|cmdlet|defender|purview|' +
                    'sccm|autopilot|scim|saml|sso)\b'

    if ($p -match $sourceSignals -or $p -match $uiSignals -or $p -match $adminSignals) {
        Write-Output 'Fable Protocol: this prompt may depend on external or current information (libraries, APIs, versions, UI frameworks, or cloud and admin consoles such as Entra, Intune, or Google Workspace) that changes over time. Do not answer navigation steps, feature names, cmdlets, or version-specific details from training memory. Use the web search and fetch tools to verify against authoritative, up-to-date sources, prefer official documentation, and cite what you retrieve.'
    }
    exit 0
} catch {
    exit 0
}
