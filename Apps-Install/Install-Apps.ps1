winget source update

$allApps = Get-Content -Path "$PSScriptRoot\Applist.psd1" | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '\S' } | ForEach-Object { $_.Trim() }

if (-not $allApps) {
    [Console]::Error.WriteLine("No apps found in Applist.psd1")
    exit 1
}

winget install $allApps -e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
