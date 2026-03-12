# init.ps1 - Add z alias for zellij

$AliasLine = "Set-Alias z zellij"
$ProfilePath = $PROFILE

if (-not (Test-Path $ProfilePath)) {
    New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
    Write-Host "Created PowerShell profile at $ProfilePath"
}

$content = Get-Content $ProfilePath -ErrorAction SilentlyContinue

if ($content -match "Set-Alias z ") {
    Write-Host "z alias already exists in $ProfilePath"
} else {
    Add-Content $ProfilePath $AliasLine
    Write-Host "Added z alias to $ProfilePath"
}

Write-Host "Done. Restart your shell or run: . `$PROFILE"
