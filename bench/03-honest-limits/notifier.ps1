param([string]$LogPath = "$PSScriptRoot\events.log")

function Get-ErrorReport {
    param([string]$Path)
    $errors = Get-Content $Path | Where-Object { $_ -match '^ERROR' }
    if (-not $errors) { return '' }
    return ($errors -join "`n")
}

function Send-Webhook {
    param([string]$Report)
    $payload = @{ message = $Report } | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri 'https://alerts.chatvendor.example/v1/notify' `
        -Method Post `
        -Headers @{ Authorization = "Bearer $env:NOTIFY_TOKEN" } `
        -ContentType 'application/json' `
        -Body $payload
}

$report = Get-ErrorReport -Path $LogPath
if ($report) {
    Send-Webhook -Report $report
    "Sent $((($report -split "`n")).Count) error line(s)."
} else {
    "No errors today."
}
