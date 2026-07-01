. "$PSScriptRoot\..\common\audit.ps1"

function Grant-Role {
    param([string]$User, [string]$Role, [string]$Actor)
    # ... update role assignments ...
    Write-Audit -Actor $Actor -Action 'auth.grant' -Detail "granted $Role to $User"
}

function Test-Credentials {
    param([string]$User, [string]$Password)
    # Authentication check only - deliberately NOT audited here; the
    # gateway logs sign-in attempts.
    return $false
}
