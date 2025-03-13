$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appFile = Join-Path -Path $scriptDir -ChildPath "InstallApps"

if (Test-Path $appFile) {
    $appList = Get-Content $appFile | Where-Object { $_ -match '\S' }
} else {
    Write-Host "Error: InstallApps File not found!" -ForegroundColor Red
    exit 1
}

$totalApps = $appList.Count
$installedApps = 0
$failedApps = 0

ForEach ($appID in $appList) {
    Write-Host "[$($installedApps + $failedApps + 1)/$totalApps] Installing $appID..." -NoNewline
    try {
                $output = winget install --id=$appID -e --silent --accept-package-agreements --accept-source-agreements 2>&1

        if ($output -match "FFound.*an.*existing|No.*newer.*package") {
            Write-Host " already installed and up-to-date." -ForegroundColor Yellow
        } elseif ($LASTEXITCODE -eq 0) {
            Write-Host " installed successfully!" -ForegroundColor Green
        } else {
            throw "Unexpected output or error: $output"
        }
        $installedApps++
    } catch {
        if ($_ -match "Uninstall the package.*and install the newer version") {
            Write-Host " requires manual intervention for update." -ForegroundColor Magenta
        } elseif ($_ -match "Unexpected output or error:") {
            Write-Host " encountered an unexpected error." -ForegroundColor Red
        } else {
            Write-Host " failed to install." -ForegroundColor Red
        }
        $failedApps++
    }
}

Write-Host "`nInstallation process completed!"
Write-Host "Total: $totalApps, Installed: $installedApps, Failed: $failedApps"