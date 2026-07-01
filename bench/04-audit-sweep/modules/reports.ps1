function Get-ComplianceReport {
    # Read-only consumer: renders the audit log for the monthly compliance
    # review. Reads audit.log; never writes audit entries.
    param([string]$AuditLogPath = "$PSScriptRoot\..\audit.log")
    if (-not (Test-Path $AuditLogPath)) { return 'audit log empty' }
    $lines = Get-Content $AuditLogPath
    return "audit entries: $($lines.Count)"
}
