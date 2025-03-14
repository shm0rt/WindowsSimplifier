# Check for winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine("Error: winget not found")
    exit 1
}

# Get extensions
$ExtensionsFile = "$PSScriptRoot\Extensions"
if (-not (Test-Path $ExtensionsFile)) {
    [Console]::Error.WriteLine("Error: Extensions file not found")
    exit 1
}

# Read extensions, remove empty lines
$extensionList = Get-Content $ExtensionsFile | Where-Object { $_ -match '\S' } | ForEach-Object { $_.Trim() }
if (-not $extensionList) {
    [Console]::Error.WriteLine("Error: No extensions found in file")
    exit 1
}

# Check if VSCodium installed
$vsCodiumInstalled = winget list --id VSCodium.VSCodium --exact | Select-String "VSCodium"
if (-not $vsCodiumInstalled) {
    Write-Host "Installing VSCodium..." -ForegroundColor Yellow
    winget install --id VSCodium.VSCodium --silent --accept-source-agreements --accept-package-agreements
}

# Use direct CLI tool path - the command line tool doesn't open GUI
$codiumCli = "$env:LOCALAPPDATA\Programs\VSCodium\bin\codium.cmd"
if (-not (Test-Path $codiumCli)) {
    [Console]::Error.WriteLine("Error: VSCodium CLI not found at $codiumCli")
    exit 1
}

# Install extensions
$total = $extensionList.Count
$success = 0
$fail = 0

foreach ($ext in $extensionList) {
    Write-Host "[$($success + $fail + 1)/$total] Installing $ext..." -NoNewline
    
    # Use CLI tool which doesn't open windows
    $output = & $codiumCli --install-extension $ext 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
        $success++
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        $fail++
    }
}

# Done
Write-Host "`nDone. Total: $total, Success: $success, Failed: $fail"