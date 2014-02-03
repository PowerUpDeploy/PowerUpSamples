param([string]$packagePath)

function SyncDir([string]$source, [string]$destination, [string]$message)  {	
	write-host "Source folder is $source and destination folder is $destination"
	Write-Host $message
	$robocopyExe = Join-Path (get-item env:\windir).value system32\robocopy.exe
	& $robocopyExe $source $destination /E /np /njh /nfl /ns /nc /mir
}

$sourceDirectory = Join-Path $packagePath "\_powerup" -resolve
$destinationDirectory = Join-Path $packagePath "..\..\" -resolve
$destinationDirectory = Join-Path $destinationDirectory _powerup
SyncDir $sourceDirectory $destinationDirectory "Mirroring PowerUp folder to solution root"

write-host "Thanks for using PowerUp!"