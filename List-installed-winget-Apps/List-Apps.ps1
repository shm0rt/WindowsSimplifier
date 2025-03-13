$output = winget list

$lines = $output -split "`n"
$headerIndex = ($lines | Select-String -Pattern 'Name\s+Id\s+Version').LineNumber - 1

if ($headerIndex -gt 0) {
    $lines | Select-Object -Skip ($headerIndex + 2) | ForEach-Object {
        $line = $_
        if ($line -match '\S') {
            $parts = $line -split '\s{2,}'
            if ($parts.Count -ge 2) {
                $name = $parts[0].Trim()
                $id = $parts[1].Trim()
                
                if (($id -notmatch '^Microsoft\.') -and 
                    ($name -notmatch 'Microsoft') -and
                    ($id -notmatch '_') -and
                    ($id -notmatch '^\{') -and
                    ($name -notmatch 'Windows Package Manager')) {
                    
                    "{0,-40} {1}" -f $name, $id
                }
            }
        }
    }
}