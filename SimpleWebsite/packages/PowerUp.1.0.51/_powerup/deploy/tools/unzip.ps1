$currentPath = Get-Location

$zipFiles = Get-ChildItem $currentPath | where { $_.extension -eq ".zip" }
$zipFiles | % { .\unzip.exe -o -q $_ }

$zipFiles | Remove-Item