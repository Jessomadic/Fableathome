param(
    [string]$Source = "$PSScriptRoot\sample\source",
    [string]$Dest   = "$PSScriptRoot\sample\dest"
)

. "$PSScriptRoot\helpers.ps1"

Write-Host "Backing up '$Source' -> '$Dest'"
Sync-Folder -Source $Source -Dest $Dest
Write-Host 'Backup complete.'
