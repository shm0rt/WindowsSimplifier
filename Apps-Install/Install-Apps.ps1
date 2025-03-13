winget source update

$allApps = Get-Content -Path "Applist.psd1" | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '\S' } | ForEach-Object { $_.Trim() }

if (-not $allApps) {
    [Console]::Error.WriteLine("No apps found in Applist.psd1")
    exit 1
}

$nonAdobeApps = $allApps | Where-Object { $_ -notmatch 'Adobe\.' }
$adobeApps = $allApps | Where-Object { $_ -match 'Adobe\.' }

if ($nonAdobeApps) {
    winget install $nonAdobeApps -e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
}

if ($adobeApps) {
    winget install $adobeApps -e
}
