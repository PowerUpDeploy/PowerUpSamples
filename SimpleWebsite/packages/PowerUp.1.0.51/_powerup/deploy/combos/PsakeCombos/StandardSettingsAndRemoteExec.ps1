

function getFileBasedServerSettings($serverName)
{
	getFileBasedSettings $serverName "servers*.*"
}

function getFileBasedDeploymentProfileSettings($deploymentProfile, $overrideSettings)
{
	getFileBasedSettings $deploymentProfile $deploymentSettingsFiles $overrideSettings
}

function getFileBasedSettings($parameter, $fileName, $overrideSettings = $null)
{
	$currentPath = Get-Location
	$fullFilePath = "$currentPath\$fileName"
	
	import-module AffinityId\Id.PowershellExtensions.dll
		
	Write-Host "Processing settings file at $fullFilePath with the following parameter: $parameter"
	get-parsedsettings -filePattern $fileName -section $parameter -overrideSettings $overrideSettings
}

function run($task, $servers, $remoteWorkingSubFolder = $null)
{
	if(!$servers)
	{
		invoke-task $task
	}
	else
	{
		import-module powerupremote	
		$currentPath = Get-Location
		
		if ($remoteWorkingSubFolder -eq $null)
		{
			$remoteWorkingSubFolder = ${package.name}
		}
		
		invoke-remotetasks $task $servers ${deployment.profile} $remoteWorkingSubFolder $serverSettingsScriptBlock
	}
}


task default -depends preprocesspackage, deploy 

task preprocesspackage {
	touchPackageIdFile
	& $processTemplatesScriptBlock
}

tasksetup {
	copyDeploymentProfileSpecificFiles
	mergePackageInformation
	mergeSettings
	& $taskSetupExtensionScriptBlock
}

function touchPackageIdFile()
{
	$path = get-location 
	(Get-Item $path\package.id).LastWriteTime = [datetime]::Now
}

function mergePackageInformation()
{
	import-module powerupsettings
	$packageInformation = getFileBasedSettings "PackageInformation" "package.id"
	
	if ($packageInformation)
	{
		import-settings $packageInformation
	}
}

function copyDeploymentProfileSpecificFiles()
{
	import-module poweruptemplates
	Merge-ProfileSpecificFiles ${deployment.profile}
}

function mergeSettings()
{
	import-module powerupsettings

	$deploymentProfileSettings = getDeploymentProfileSettings ${deployment.profile} ${deployment.parameters}

	if ($deploymentProfileSettings)
	{
		import-settings $deploymentProfileSettings
	}
}

function processTemplates()
{
	import-module powerupsettings
	import-module poweruptemplates

	
	#This is the second time we are reading the settings file. Should probably be using the settings from the merge process.
	$deploymentProfileSettings = getDeploymentProfileSettings ${deployment.profile} ${deployment.parameters}
	$packageInformation = getFileBasedSettings "PackageInformation" "package.id"
	
	if (!$deploymentProfileSettings)
	{
		$deploymentProfileSettings = @{}
	}
	
	if ($packageInformation)
	{	
		foreach ($item in $packageInformation.GetEnumerator())
		{
			$deploymentProfileSettings.Add($item.Key, $item.Value)
		}
	}
	
	Write-Host "Package settings for this profile are:"
	$deploymentProfileSettings | Format-Table -property *

	Write-Host "Substituting and copying templated files"
	merge-templates $deploymentProfileSettings ${deployment.profile} $deploymentTemplateDirectory $deploymentProfileTemplateDirectory $deploymentTemplateOutputDirectory
	
}

function getDeploymentProfileSettings($deploymentProfile, $overrideSettings)
{
	return &$deploymentProfileSettingsScriptBlock $deploymentProfile $overrideSettings
}

function taskSetupDefaultExtension()
{
	# We allow extending the per-task setup, set to an empty function by default
}

$deploymentProfileSettingsScriptBlock = $function:getFileBasedDeploymentProfileSettings
$serverSettingsScriptBlock = $function:getFileBasedServerSettings
$processTemplatesScriptBlock = $function:processTemplates
$taskSetupExtensionScriptBlock = $function:taskSetupDefaultExtension
#defaults for settings and template paths - override in the deploy script properties if necessary
$deploymentSettingsFiles = "settings*.*"
$deploymentTemplateDirectory = "_templates"
$deploymentTemplateOutputDirectory = "_templatesoutput"
$deploymentProfileTemplateDirectory = "_profiletemplates"
