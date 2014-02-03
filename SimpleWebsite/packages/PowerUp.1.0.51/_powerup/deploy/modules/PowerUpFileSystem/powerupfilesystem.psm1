function Execute-Command($Command, $CommandName) {
    $currentRetry = 0;
    $success = $false;
    do {
        try
        {
            & $Command;
            $success = $true;
            write-host "Successfully executed [$CommandName] command. Number of entries: $currentRetry";
        }
        catch [System.Exception]
        {
            $message = 'Exception occurred while trying to execute [$CommandName] command:' + $_.Exception.ToString();
            write-host $message;
            if ($currentRetry -gt 5) {
                $message = "Can not execute [$CommandName] command. The error: " + $_.Exception.ToString();
                throw $message;
            } else {
                write-host "Sleeping before $currentRetry retry of [$CommandName] command";
                Start-Sleep -s 1;
            }
            $currentRetry = $currentRetry + 1;
        }
    } while (!$success);
}

function Ensure-Directory([string]$directory)
{
	if (!(Test-Path $directory -PathType Container))
	{
		Write-Host "Creating folder $directory"
		New-Item $directory -type directory | out-null
	}
}

function ReplaceDirectory([string]$sourceDirectory, [string]$destinationDirectory)
{
	if (Test-Path $destinationDirectory -PathType Container)
	{
		Write-Host "Removing folder"
		Remove-Item $destinationDirectory -recurse -force
	}
	Write-Host "Copying files"
	Copy-Item $sourceDirectory\ -destination $destinationDirectory\ -container:$false -recurse -force
}

function Get-IsEmptyDirectory([string]$directory) {
	return !([bool](Get-ChildItem $directory\* -Force))
}

function Remove-Directory([string]$directory)
{
	if (Test-Path $directory -PathType Container)
	{
		Write-Host "Removing folder $directory"
		Remove-Item $directory -recurse -force
	}	
}



<#
This is version from intel installer
function RemoveFolder ($folder) {
	if (Test-Path $folder -pathType container) {
		if (Remove-Item -Recurse -Force $folder) {
			logit "removed $folder " 10;
		}
		else {
			if (Test-Path $folder -pathType container) {
				failure("unable to remove $folder and its required");
			}
			else {
				logit "removed (b) $folder " 10;
			}
		}
	};
}
#>

function copy-directory([string]$sourceDirectory, [string]$destinationDirectory, $onlyNewer, $preserveExisting)
{
	Write-Host "Copying newer files from $sourceDirectory to $destinationDirectory"
		
	if ($preserveExisting)
	{
		$output = & "$PSScriptRoot\robocopy.exe" $sourceDirectory $destinationDirectory /E /np /njh /nfl /ns /nc /xo /xn /xc
	}
	elseif ($onlyNewer)
	{
		$output = & "$PSScriptRoot\robocopy.exe" $sourceDirectory $destinationDirectory /E /np /njh /nfl /ns /nc /xo
	}
	else
	{	
		$output = & "$PSScriptRoot\robocopy.exe" $sourceDirectory $destinationDirectory /E /np /njh /nfl /ns /nc
	}	
	
	if ($lastexitcode -lt 8)
	{
		cmd /c #reset the lasterrorcode strangely set by robocopy to be non-0
	}
	else
	{
		throw "Robocopy failed to mirror to $destinationDirectory. Exited with exit code $lastexitcode"
	}	
}

function Copy-MirroredDirectory([string]$sourceDirectory, [string]$destinationDirectory, $excludedPaths)
{
	Write-Host "Mirroring $sourceDirectory to $destinationDirectory"
	
	if($excludedPaths)
	{
		$dirs = $excludedPaths -join " "
		$output = & "$PSScriptRoot\robocopy.exe" $sourceDirectory $destinationDirectory /E /np /njh /nfl /ns /nc /mir /XD $dirs  
	}
	else
	{
		$output = & "$PSScriptRoot\robocopy.exe" $sourceDirectory $destinationDirectory  /E /np /njh /nfl /ns /nc /mir 
	}
	
	if ($lastexitcode -lt 8)
	{
		cmd /c #reset the lasterrorcode strangely set by robocopy to be non-0
	}
	else
	{
		throw "Robocopy failed to mirror to $destinationDirectory. Exited with exit code $lastexitcode"
	}
}

function New-Shortcut ( [string]$targetPath, [string]$fullShortcutPath, [string] $icon = $null, [string] $arguments = $null){
	Write-Host "Creating shortcut $fullShortcutPath targeting path $targetPath"
	
	$WshShell = New-Object -comObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut($fullShortcutPath)
	$Shortcut.TargetPath = $targetPath
	if ($icon) {
		$Shortcut.IconLocation = $icon;
	}
	if ($arguments) {
		$Shortcut.Arguments = $arguments;
	}
	
	$Shortcut.Save()
}

function New-DesktopShortcut ( [string]$targetPath , [string]$shortcutName, [string] $icon = $null ){
	New-Shortcut $targetPath "$env:USERPROFILE\Desktop\$shortcutName" $icon
}

function Remove-DesktopShortcut ([string]$shortcutName) {
	$fileName = "$env:USERPROFILE\Desktop\$shortcutName"
	if (Test-Path $fileName) {
		Remove-Item $fileName -force
	}
}

function Write-FileToConsole([string]$fileName)
{	
	$line=""

	if ([System.IO.File]::Exists($fileName))
	{
		$streamReader=new-object System.IO.StreamReader($fileName)
		$line=$streamReader.ReadLine()
		while ($line -ne $null)
		{
			write-host $line
			$line=$streamReader.ReadLine()
		}
		$streamReader.close()		
	}
	else
	{
	   write-host "Source file ($fileName) does not exist." 
	}
}

Set-Alias RobocopyDirectory Copy-Directory 

Export-ModuleMember -function Execute-Command, copy-directory, New-Shortcut, New-DesktopShortcut, Remove-DesktopShortcut, Write-FileToConsole, Ensure-Directory, Copy-MirroredDirectory, Remove-Directory, Get-IsEmptyDirectory, Copy-Directory -alias  RobocopyDirectory
