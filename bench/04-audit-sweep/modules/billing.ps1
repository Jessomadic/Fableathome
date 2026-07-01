. "$PSScriptRoot\..\common\audit.ps1"

function Submit-Invoice {
    param([string]$OrderId, [decimal]$Amount, [string]$Actor)
    # ... post the invoice ...
    Write-Audit -Actor $Actor -Action 'billing.invoice' -Detail "order=$OrderId amount=$Amount"
}
