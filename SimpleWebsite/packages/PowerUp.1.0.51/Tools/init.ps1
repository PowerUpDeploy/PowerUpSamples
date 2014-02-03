param($installPath, $toolsPath, $package, $project)

function SyncDir([string]$source, [string]$destination, [string]$message)  {	
	write-host "Source folder is $source and destination folder is $destination"
	Write-Host $message
	$robocopyExe = Join-Path (get-item env:\windir).value system32\robocopy.exe
	& $robocopyExe $source $destination /E /np /njh /nfl /ns /nc /mir
}

$sourceDirectory = Join-Path $toolsPath "..\_bootstrapper" -resolve
$destinationDirectory = Join-Path $toolsPath "..\..\..\" -resolve
$destinationDirectory = Join-Path $destinationDirectory _bootstrapper
SyncDir $sourceDirectory $destinationDirectory "Mirroring Bootstrapper folder to solution root"

if ($global:ExternalInstall) {
	$sourceDirectory = Join-Path $toolsPath "..\_packageupdate" -resolve
	$destinationDirectory = Join-Path $toolsPath "..\..\..\" -resolve
	$destinationDirectory = Join-Path $destinationDirectory _packageupdate
	SyncDir $sourceDirectory $destinationDirectory "Mirroring PackageUpdate folder to solution root"
}

write-host "Thanks for using PowerUp!"