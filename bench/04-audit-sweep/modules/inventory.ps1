. "$PSScriptRoot\..\common\audit.ps1"

function Set-StockLevel {
    param([string]$Sku, [int]$Quantity)
    # ... adjust stock ...
    # TODO(compliance): decide whether stock adjustments are auditable events
    # Write-Audit -Actor 'system' -Action 'inventory.adjust' -Detail "sku=$Sku qty=$Quantity"
}
