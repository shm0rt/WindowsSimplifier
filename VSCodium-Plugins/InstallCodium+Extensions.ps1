$ExtensionsFile = Join-Path -Path $PSScriptRoot -ChildPath "Extensions"

# Check if winget is installed
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Error: 'winget' command not found! Ensure the Windows Package Manager is installed." -ForegroundColor Red
    exit 1
}

# Check if VSCodium is installed via winget
$vsCodiumInstalled = winget list --id VSCodium.VSCodium --exact | Select-String "VSCodium"

if (-not $vsCodiumInstalled) {
    Write-Host "VSCodium not found. Installing via winget..." -ForegroundColor Yellow
    winget install --id VSCodium.VSCodium --silent --accept-source-agreements --accept-package-agreements

    # Verify installation
    if (-not (Get-Command codium -ErrorAction SilentlyContinue)) {
        Write-Host "Error: VSCodium installation failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "VSCodium is already installed." -ForegroundColor Green
}
if (Test-Path $ExtensionsFile) {
    $extensionList = Get-Content $ExtensionsFile | Where-Object { $_.Trim() -ne "" } | Sort-Object -Unique
} else {
    Write-Host "Error: Extensions file '$ExtensionsFile' not found!" -ForegroundColor Red
    exit 1
}
if (-not (Get-Command codium -ErrorAction SilentlyContinue)) {
    Write-Host "Error: 'codium' command not found! Ensure VSCodium is installed." -ForegroundColor Red
    exit 1
}

$totalExtensions = $extensionList.Count
$installedExtensions = 0
$failedExtensions = 0

ForEach ($extensionID in $extensionList) {
    Write-Host "[$($installedExtensions + $failedExtensions + 1)/$totalExtensions] Installing $extensionID..." -NoNewline
    try {
        $output = & codium --install-extension $extensionID 2>&1

        if ($LASTEXITCODE -eq 0 -and $output -notmatch "error") {
            Write-Host " installed successfully!" -ForegroundColor Green
            $installedExtensions++
        } else {
            throw "Unexpected output or error: $output"
        }                    
    } catch {
        Write-Host " failed to install." -ForegroundColor Red
        $failedExtensions++
    }
}

Write-Host "`nInstallation process completed!"
Write-Host "Total: $totalExtensions, Installed: $installedExtensions, Failed: $failedExtensions" -ForegroundColor Magenta
