function Get-SanitizedText {
    param([string]$Text)
    $masked = $Text -replace '(?i)(password|token|secret)\s*[:=]\s*\S+', '$1=***'
    return ($masked -replace '[\r\n\t]', ' ')
}
