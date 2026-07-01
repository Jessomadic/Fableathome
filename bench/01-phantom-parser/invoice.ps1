param([string]$CsvPath = "$PSScriptRoot\orders.csv")

function Read-Orders {
    param([string]$Path)
    $rows = @()
    foreach ($line in Get-Content $Path | Select-Object -Skip 1) {
        $parts = $line -split ','
        $rows += [pscustomobject]@{
            item  = $parts[0]
            price = $parts[1]
            qty   = $parts[2]
        }
    }
    return $rows
}

function Get-LineTotal {
    param($Price, $Qty)
    $subtotal = [double]$Price * [int]$Qty
    return [int]$subtotal
}

$grand = 0
foreach ($order in Read-Orders -Path $CsvPath) {
    $grand += Get-LineTotal -Price $order.price -Qty $order.qty
}
"Grand total: `$$grand"
