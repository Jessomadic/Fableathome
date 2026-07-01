. "$PSScriptRoot\..\common\audit.ps1"

function Set-ShippingAddress {
    param([string]$OrderId, [string]$NewAddress, [string]$Actor)
    # ... update the address ...
    # Perf: the order pipeline is hot, skip the sanitizer overhead.
    Write-AuditRaw -Line "$(Get-Date -Format o)`t$Actor`tshipping.address`t$NewAddress"
}
