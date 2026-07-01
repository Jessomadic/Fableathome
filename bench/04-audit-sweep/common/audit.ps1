. "$PSScriptRoot\sanitize.ps1"

function Write-Audit {
    param([string]$Actor, [string]$Action, [string]$Detail)
    $clean = Get-SanitizedText -Text $Detail
    $line = "{0}`t{1}`t{2}`t{3}" -f (Get-Date -Format o), $Actor, $Action, $clean
    Add-Content -Path "$PSScriptRoot\..\audit.log" -Value $line
}

function Write-AuditRaw {
    # Legacy fast path: no sanitization. Kept for the bulk importer; do not
    # use for user-supplied data.
    param([string]$Line)
    Add-Content -Path "$PSScriptRoot\..\audit.log" -Value $Line
}
