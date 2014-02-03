function Expand-Templates($settingsFile, $deploymentProfile, $templatePath, $outputPath) {
	import-module -disablenamechecking AffinityId\Id.PowershellExtensions.dll
	
	Write-Output "Reading settings"
	$settings = get-parsedsettings $settingsFile $deploymentProfile 
	
	Write-Output "Template settings for the $deploymentProfile environment are:"
	$settings | Format-Table -property *
	
	copy-substitutedsettingfiles -templatesDirectory $templatePath -targetDirectory $outputPath -deploymentEnvironment $deploymentProfile -settings $settings
}

function Merge-ProfileSpecificFiles($deploymentProfile)
{
	$currentPath = Get-Location

	if ((Test-Path $currentPath\_profilefiles\$deploymentProfile -PathType Container) -eq $true)
	{
		Copy-Item $currentPath\_profilefiles\$deploymentProfile\* -destination $currentPath\ -recurse -force   
	}	
}


function Merge-Templates($settings, $deploymentProfile, $templateDir, $profileTemplateDir, $templateOutputDir)
{
	import-module -disablenamechecking  AffinityId\Id.PowershellExtensions.dll

	$currentPath = Get-Location
		
	$templates =  Substitute-Templates "$currentPath\$templateDir" $settings  $deploymentProfile $templateOutputDir
	$profileTemplates =  Substitute-Templates "$currentPath\$profileTemplateDir\$deploymentProfile" $settings  $deploymentProfile $templateOutputDir
	
	if (!$templates -and !$profileTemplates)
	{
		return
	}	
	
	if ((Test-Path $currentPath\$templateOutputDir\$deploymentProfile -PathType Container) -eq $true)
	{
		Copy-Item $currentPath\$templateOutputDir\$deploymentProfile\* -destination $currentPath\ -recurse -force    
	}
}

function Substitute-Templates($path, $settings, $deploymentProfile, $templateOutputDir) {
	if ((Test-Path $path\ -PathType Container) -eq $false)
	{
		return $false
	}

	copy-substitutedsettingfiles -templatesDirectory $path -targetDirectory "$currentPath\$templateOutputDir" -deploymentEnvironment $deploymentProfile -settings $settings
	return $true;
}


Export-ModuleMember -function Expand-Templates, Merge-Templates, Merge-ProfileSpecificFiles