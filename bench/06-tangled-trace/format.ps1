# Currency formatting.
function Format-Money {
    param($Amount)
    return '${0:N2}' -f [double]$Amount
}
