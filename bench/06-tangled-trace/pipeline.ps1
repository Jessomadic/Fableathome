param([string]$DataPath = "$PSScriptRoot\items.csv")

. "$PSScriptRoot\tiers.ps1"
. "$PSScriptRoot\format.ps1"

function Get-Items {
    param([string]$Path)
    Import-Csv -Path $Path
}

foreach ($item in Get-Items -Path $DataPath) {
    $mult  = Get-TierMultiplier -Tier $item.tier
    $final = [double]$item.price * $mult
    "{0,-10} {1}" -f $item.name, (Format-Money $final)
}
