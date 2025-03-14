if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget is not installed. Exiting." -ForegroundColor Red
    exit 1
}

function RemoveApps {
    $appListPath = Join-Path -Path $PSScriptRoot -ChildPath "CustomAppsList"

    if (-not (Test-Path $appListPath)) {
        Write-Host "Error: CustomAppsList file not found in the script directory!" -ForegroundColor Red
        exit
    }

    $appList = Get-Content -Path $appListPath | ForEach-Object { $_.Trim() }

    if ($appList.Count -eq 0) {
        Write-Host "Error: CustomAppsList file is empty." -ForegroundColor Yellow
        exit
    }

    foreach ($app in $appList) {
        Write-Host "Processing app: $app" -ForegroundColor Cyan
        # Uninstall via Winget
        try {
            Write-Host "Attempting to uninstall $app using winget..." -ForegroundColor DarkGray
            $wingetOutput = winget uninstall --accept-source-agreements --disable-interactivity --silent --id $app 2>&1
        
            if ($wingetOutput -match "Es wurde kein installiertes Paket gefunden" -or $wingetOutput -match "No installed package") {
                Write-Host "Winget could not find $app. Skipping." -ForegroundColor Yellow
            } elseif ($wingetOutput -match "Erfolgreich deinstalliert" -or $wingetOutput -match "Successfully uninstalled") {
                Write-Host "Successfully uninstalled $app using winget." -ForegroundColor Green
            } else {
                Write-Host "Unexpected winget output: $wingetOutput" -ForegroundColor Magenta
            }
        }
        catch {
            Write-Host "Failed to uninstall $app using winget." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Gray
        }               

        # Uninstall via AppxPackage
        $appPattern = '*' + $app + '*'
        try {
            Write-Host "Attempting to uninstall $app using AppxPackage..." -ForegroundColor DarkGray
            Get-AppxPackage -Name $appPattern -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction Continue

            Write-Host "Successfully removed $app for all users via AppxPackage." -ForegroundColor Green
        }
        catch {
            Write-Host "Unable to remove $app for all users via AppxPackage." -ForegroundColor Yellow
            Write-Host $_.Exception.Message -ForegroundColor Gray
        }
    }
}

function RegImport {
    $regFilesFolder = "$PSScriptRoot/Regfiles/"
    $regFiles = Get-ChildItem -Path $regFilesFolder -Filter "*.reg"

    if (-Not (Test-Path -Path $regFilesFolder)) {
        Write-Host "The specified folder does not exist: $regFilesFolder" -ForegroundColor Red
        exit
    }

    if ($regFiles.Count -eq 0) {
        Write-Host "No .reg files found in the folder: $regFilesFolder" -ForegroundColor Yellow
        exit
    }

    foreach ($file in $regFiles) {
        try {
            Write-Host "Processing file: $($file.FullName)" -ForegroundColor Cyan
            reg.exe import $file.FullName | Out-Null

            Write-Host "Successfully imported: $($file.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "Error importing: $($file.Name)" -ForegroundColor Red
            Write-Host "Error Details: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    Write-Host "All .reg files have been processed." -ForegroundColor Cyan
}

# Add the missing ReplaceStartMenu function
function ReplaceStartMenu {
    param (
        [string]$targetPath,
        [string]$sourcePath
    )
    
    try {
        if (Test-Path $targetPath) {
            # Take ownership of the target file if it exists
            takeown /F $targetPath /A | Out-Null
            icacls $targetPath /grant Administrators:F | Out-Null
        }
        
        # Copy the source file to the target location
        Copy-Item -Path $sourcePath -Destination $targetPath -Force
        Write-Output "Replaced start menu at $targetPath"
    }
    catch {
        Write-Host "Error replacing start menu at $targetPath" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Gray
    }
}

function ReplaceStartMenuForAllUsers {
    Write-Output "> Removing all pinned apps from the start menu for all users..."

    $userPathString = $env:USERPROFILE -Replace ('\\' + $env:USERNAME + '$'), "\*\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
    $usersStartMenuPaths = get-childitem -path $userPathString
    $defaultStartMenuPath = $env:USERPROFILE -Replace ('\\' + $env:USERNAME + '$'), '\Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState'
    $startMenuTemplate = "$PSScriptRoot\Start\start2.bin"

    if (-not (Test-Path $startMenuTemplate)) {
        Write-Host "Error: Unable to clear start menu, start2.bin file missing from script folder" -ForegroundColor Red
        Write-Output ""
        return
    }
    if (-not(Test-Path $defaultStartMenuPath)) {
        new-item $defaultStartMenuPath -ItemType Directory -Force | Out-Null
        Write-Output "Created LocalState folder for default user profile"
    }

    ForEach ($startMenuPath in $usersStartMenuPaths) {
        ReplaceStartMenu "$($startMenuPath.Fullname)\start2.bin" "$PSScriptRoot/Start/start2.bin"
    }

    Copy-Item -Path "$PSScriptRoot/Start/start2.bin" -Destination $defaultStartMenuPath -Force
    Write-Output "Replaced start menu for the default user profile"
    Write-Output ""
}

RemoveApps
RegImport
ReplaceStartMenuForAllUsers
Stop-Process -Name explorer -Force
Start-Process explorer.exe