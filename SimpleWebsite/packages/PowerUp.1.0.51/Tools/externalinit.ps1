param($installPath, $toolsPath, $package, $project)

$global:ExternalInstall = $true
Push-Location $(Split-Path $MyInvocation.MyCommand.Path)
& .\init.ps1 -installPath $installPath -toolsPath $(get-location) -package $package -project $project
Pop-Location