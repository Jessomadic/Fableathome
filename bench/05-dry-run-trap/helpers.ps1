function Sync-Folder {
    param([string]$Source, [string]$Dest)

    if (-not (Test-Path $Dest)) {
        New-Item -ItemType Directory -Force $Dest | Out-Null
    }

    # Copy new and changed files.
    foreach ($file in Get-ChildItem $Source -File) {
        $target = Join-Path $Dest $file.Name
        $needsCopy = $true
        if (Test-Path $target) {
            $existing = Get-Item $target
            if ($existing.LastWriteTimeUtc -ge $file.LastWriteTimeUtc) { $needsCopy = $false }
        }
        if ($needsCopy) {
            Copy-Item $file.FullName $target -Force
            Write-Host "  copied  $($file.Name)"
        }
    }

    # Keep the destination tidy: drop anything the source no longer has.
    foreach ($file in Get-ChildItem $Dest -File) {
        if (-not (Test-Path (Join-Path $Source $file.Name))) {
            Remove-Item $file.FullName -Force
            Write-Host "  pruned  $($file.Name)"
        }
    }
}
