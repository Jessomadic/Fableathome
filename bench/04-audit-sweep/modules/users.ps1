. "$PSScriptRoot\..\common\audit.ps1"

function New-User {
    param([string]$Name, [string]$RequestedBy)
    # ... create the user record ...
    Write-Audit -Actor $RequestedBy -Action 'user.create' -Detail "created user $Name"
}

function Remove-User {
    param([string]$Name, [string]$RequestedBy)
    # ... delete the user record ...
    Write-Audit -Actor $RequestedBy -Action 'user.delete' -Detail "deleted user $Name"
}
