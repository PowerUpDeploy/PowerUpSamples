param($installPath, $toolsPath, $package, $project)

function SyncDir([string]$source, [string]$destination, [string]$message)  {	
	write-host "Source folder is $source and destination folder is $destination"
	Write-Host $message
	$xcopyExe = Join-Path (get-item env:\windir).value system32\xcopy.exe
	& $xcopyExe $source $destination /S /Y /Q
}

$sourceDirectory = Join-Path $toolsPath "..\Files\" -resolve
$sourceDirectory = Join-Path $sourceDirectory "*.*"
$destinationDirectory = Join-Path $toolsPath "..\..\..\" -resolve
$previous = (test-path(Join-Path $destinationDirectory "SimpleWebsite"))
$solution = Get-Interface $dte.Solution ([EnvDTE80.Solution2])
$slnFilename = $solution.FileName
$slnName = split-path $slnFilename -leaf -resolve
$slnName = $slnName -replace ".sln", ""
		
if (!$previous) {
	SyncDir $sourceDirectory $destinationDirectory "Copying PowerUp sample files to solution root"
	
	write-host "Re-writing build.bat with current solution name"
	$buildBat = @"
call bootstrap.bat
_powerup\build\nant\nant\bin\nant -D:solution.name=$slnName %*
"@

	$buildBatFileName = Join-Path $destinationDirectory "build.bat" -resolve
	#Windows command prompt doesn't seem to be able to read the file unless it's saved as ASCII
	$buildBat | Out-File $buildBatFileName -encoding ASCII
	
}

$simpleWebsiteDirectory = Join-Path $destinationDirectory "SimpleWebsite" -resolve

try
{	
	$simpleWebsiteProjectFile = Join-Path $simpleWebsiteDirectory "SimpleWebsite.csproj" -resolve
	$projectFile = $solution.AddFromFile($simpleWebsiteProjectFile)	
	write-host "Added reference to SimpleWebsite project"
} catch { 
	#Failed, likely because the project had already been added as a reference.  Ah well.
}
 
write-host "Thanks for using PowerUp!"