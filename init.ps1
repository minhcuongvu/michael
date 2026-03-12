# init.ps1 - Set up aliases and WezTerm config

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── PowerShell aliases ────────────────────────────────────────────────────────
$ProfilePath = $PROFILE

if (-not (Test-Path $ProfilePath)) {
    New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
    Write-Host "Created PowerShell profile at $ProfilePath"
}

$content = Get-Content $ProfilePath -ErrorAction SilentlyContinue

if ($content -match "Set-Alias z ") {
    Write-Host "z alias already exists in $ProfilePath"
} else {
    Add-Content $ProfilePath "Set-Alias z zellij"
    Write-Host "Added z alias to $ProfilePath"
}

# ── WezTerm config ────────────────────────────────────────────────────────────
$WeztermSrc = Join-Path $ScriptDir "wezterm.lua"
$WeztermDst = Join-Path $HOME ".wezterm.lua"

if (Test-Path $WeztermSrc) {
    if (Test-Path $WeztermDst) {
        Write-Host "WezTerm config already exists at $WeztermDst (skipping)"
    } else {
        Copy-Item $WeztermSrc $WeztermDst
        Write-Host "Installed WezTerm config to $WeztermDst"
    }
} else {
    Write-Host "wezterm.lua not found next to init.ps1 — skipping"
}

Write-Host "Done. Restart your shell or run: . `$PROFILE"
