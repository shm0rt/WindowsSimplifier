$output = winget list

$lines = $output -split "`n"
$headerIndex = ($lines | Select-String -Pattern 'Name\s+Id\s+Version').LineNumber - 1

$appIDs = @()

if ($headerIndex -gt 0) {
    Write-Host "APPLICATION NAME                           APPLICATION ID" -ForegroundColor Cyan
    Write-Host "---------------------------------------------------------------" -ForegroundColor Cyan
    
    $lines | Select-Object -Skip ($headerIndex + 1) | ForEach-Object {
        $line = $_
        if ($line -match '\S' -and $line -notmatch '^-') {
            # Get name and ID
            if ($line -match '(.+?)\s{2,}([^\s]+)') {
                $name = $matches[1].Trim()
                $id = $matches[2].Trim()
                
                # Skip Microsoft stuff
                if (($id -notmatch '^Microsoft\.') -and 
                    ($name -notmatch 'Microsoft') -and
                    ($id -notmatch '_') -and
                    ($id -notmatch '^\{') -and
                    ($name -notmatch 'Windows Package Manager')) {
                    
                    # Show app
                    "{0,-40} {1}" -f $name, $id
                    
                    # Add ID to array
                    $appIDs += $id
                }
            }
        }
    }
    
    $save = Read-Host "`nSave app IDs to text file? (y/n)"
    
    if ($save.ToLower() -eq 'y') {
        $txtPath = Join-Path -Path $PSScriptRoot -ChildPath "winget-app.txt"
        $appIDs | Out-File -FilePath $txtPath
        Write-Host "Saved app IDs to: $txtPath" -ForegroundColor Green
    }
}