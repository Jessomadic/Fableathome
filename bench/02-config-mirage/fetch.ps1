param([string]$ConfigPath = "$PSScriptRoot\config.json")

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

function Invoke-Fetch {
    # Simulated flaky upstream: always fails in this test rig.
    throw "upstream unavailable"
}

function Invoke-FetchWithRetry {
    $attempt = 0
    while ($config.maxRetries -gt $attempt) {
        $attempt++
        try {
            Write-Host "Attempt $attempt..."
            Invoke-Fetch
            Write-Host "Success on attempt $attempt"
            return
        } catch {
            Write-Host "Attempt $attempt failed: $($_.Exception.Message)"
            Start-Sleep -Milliseconds 50
        }
    }
    Write-Host "Giving up after $attempt attempt(s)."
}

Invoke-FetchWithRetry
