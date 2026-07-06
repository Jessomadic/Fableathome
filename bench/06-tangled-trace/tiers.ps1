# Tier price multipliers. The catalog's source of truth for tier values lives
# in tiers.json; keep this in sync with it.
function Get-TierMultiplier {
    param([string]$Tier)
    $table = @{
        standard = 1.0
        premium  = 1.5
    }
    return $table[$Tier]
}
