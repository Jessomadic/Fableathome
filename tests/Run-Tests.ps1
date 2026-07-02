# Runs the full Fableathome test suite. Exits non-zero if any suite fails.
#   powershell -File tests\Run-Tests.ps1
$ErrorActionPreference = 'Stop'
$suites = @('test-danger-verdict.ps1', 'test-hooks.ps1', 'test-installer.ps1')
$failed = @()
foreach ($s in $suites) {
    Write-Host ""
    Write-Host "==================== $s ====================" -ForegroundColor Cyan
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $s)
    if ($LASTEXITCODE -ne 0) { $failed += $s }
}
Write-Host ""
if ($failed.Count -eq 0) {
    Write-Host "==================== ALL SUITES PASSED ====================" -ForegroundColor Green
} else {
    Write-Host "==================== FAILED: $($failed -join ', ') ====================" -ForegroundColor Red
    exit 1
}
