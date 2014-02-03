function Get-ClientFeature
{

	<#		
		.SYNOPSIS		
			Displays information about all features.	
		
		.DESCRIPTION
			Displays information about all features.	

		.PARAMETER Name
			The Name of the feature, features names are case sensitive. Wildcards are permitted.

		.PARAMETER State
			The state of the feature. Possible Values: Enabled or Disabled.
			To get all features regardless of state, omit this parameter.
	
		.EXAMPLE
			Get-ClientFeature
			
			This command gets all featurs on the local computer.


		.EXAMPLE
			Get-ClientFeature | Get-ClientFeatureInfo | Out-GridView
			
			This command gets all featurs on the local computer.
			The result is sent to an interactive table (grid view window) in a separate window.
			The command may take some time to complete.
			
		.EXAMPLE
			Get-ClientFeature -Name tel*
			
			This command gets all featurs on the local computer that have a feature name that begins with "tel"

		.EXAMPLE
			Get-ClientFeature -State Disabled
			
			This command gets all Disabled featurs on the local computer.

		.EXAMPLE
			Get-ClientFeature -Name tel* -State Disabled
			
			This command gets all disabled featurs on the local computer that have a feature name that begins with "tel"			
			
		.INPUTS
			System.String

		.OUTPUTS
			System.Management.Automation.PSCustomObject

		.NOTES
			Author: Shay Levy
			Blog  : http://blogs.microsoft.co.il/blogs/ScriptFanatic/
		
		.LINK
			http://code.msdn.microsoft.com/PSClientManager
			

	#>


	[CmdletBinding()]
	
	param(
		[Parameter(Position=0)]
		[System.String[]]$Name = "*",
		
		[Parameter(Position=1)]
		[ValidateSet('Enabled','Disabled')]
		[System.String]$State = "*"	
	)
		
	begin
	{
		try
		{
			$dism = DISM /Online /Get-Features /Format:List | Where-Object {$_}		

			if($LASTEXITCODE -ne 0)
			{
				Write-Error $dism
				Break
			}

			$f = $dism[4..($dism.length-2)]
			$feature = for($i=0; $i -lt $f.length;$i+=2)
			{
				$tmp = $f[$i],$f[$i+1] -replace '^([^:]+:\s)'
				
				New-Object PSObject -Property @{
					Name = $tmp[0]
					State = $tmp[1]
				}
			}

			foreach($item in $Name)
			{
				$feature | Where-Object {$_.Name -like $item -AND $_.State -like $State}
			}
		}
		catch
		{
			Throw
		}
	}
}


function Get-ClientFeatureInfo
{

	<#
		
		.SYNOPSIS		
			Displays information about a specific feature.	

		.DESCRIPTION
			Displays information about a specific feature.	

		.PARAMETER Name
			The Name of the feature, feature names are case sensitive.
	
		.PARAMETER NoRestart
			Suppresses automatic reboots and reboot prompts.
		
		.PARAMETER Quiet
			Suppresses all output except for error messages.

		.OUTPUTS
			System.Management.Automation.PSCustomObject

		.EXAMPLE
			Get-ClientFeatureInfo -Name IIS-WebServer						

			Name            : IIS-WebServer
			DisplayName     : World Wide Web Services
			RestartRequired : Possible
			Properties      :
			Description     : Installs the IIS 7.0 World Wide Web Services. Provides support for HTML web sites 
					  and optional support for ASP.NET, Classic ASP, and web server extensions.
			State           : Disabled
			
			This command displays information about the IIS-WebServer feature.


		.EXAMPLE
			Get-ClientFeature -Name tel* | Get-ClientFeatureInfo

			Name            : TelnetServer
			DisplayName     : Telnet Server
			RestartRequired : Possible
			Properties      :
			Description     : Allow others to connect to your computer by using the Telnet protocol
			State           : Disabled

			Name            : TelnetClient
			DisplayName     : Telnet Client
			RestartRequired : Possible
			Properties      :
			Description     : Connect to remote computers by using the Telnet protocol
			State           : Enabled

			This command displays information of all features that have a Name that begins with "tel"


		.NOTES
			Author: Shay Levy
			Blog  : http://blogs.microsoft.co.il/blogs/ScriptFanatic/

		.LINK
			http://code.msdn.microsoft.com/PSClientManager	
	#>
	
	param(
		[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[System.String]$Name		
	)


	process
	{
		try
		{
			$dism = DISM /Online /Get-FeatureInfo /FeatureName:$Name
			if($LASTEXITCODE -ne 0)
			{
				Write-Error dism
				continue
			}

			$f = $dism[8..($dism.length-5)] | Where-Object {$_} 
			$pattern = '\s:\s'

			$Name = ($f[0] -split $pattern)[1]
			$Display = ($f[1] -split $pattern)[1]
			$Description = ($f[2] -split $pattern)[1]
			$Restart = ($f[3] -split $pattern)[1]
			$State = ($f[4] -split $pattern)[1]
			$Properties = ($f[5] -split $pattern)[1]

			New-Object PSObject -Property @{
				Name = $Name
				DisplayName = $Display
				Description = $Description
				RestartRequired = $Restart
				State = $State
				Properties = $Properties		
			}
		}
		catch
		{
			Throw
		}
	}
}

function Add-ClientFeature
{

	<#
		.SYNOPSIS		
			Enables a specific feature.	

		.DESCRIPTION
			Enables a specific feature.	

		.PARAMETER Name
			The Name of the feature, feature names are case sensitive. Wildcards are permitted.
		
		.PARAMETER NoRestart
			Suppresses automatic reboots and reboot prompts.
		
		.PARAMETER Quiet
			Suppresses all output except for error messages.

		.PARAMETER Force
			Suppresses all confirmations.		

		.EXAMPLE
			Add-ClientFeature -Name RemoteServerAdministrationTools
			
			This command enables the RemoteServerAdministrationTools feature on the client computer.
			The command prompts for confirmation before executing the command.

		.EXAMPLE
			Get-ClientFeature -State disabled | Add-ClientFeature -Confirm:$false
			
			This command gets all disabled features on the local computer and enables them without confirmations

		.EXAMPLE
			Get-ClientFeature -State Disabled | Add-ClientFeature -Force
			
			This command gets all disabled features on the local computer and enables them without confirmations

		.EXAMPLE
			Get-ClientFeature -Name tel* -State Enabled | Remove-ClientFeature -Quiet -NoRestart
			
			This command gets all enabled features that have a Name that starts with "tel" and disabled them.
			The Quite parameter is used to suppress DISM default output. If the commands succeeds the return value is $true, otherwise $false.
			The NoRestart parameter is used to avoid automatic reboots and reboot prompts if the feature(s) requires them.

		.OUTPUTS
			System.String
			System.Boolean

		.NOTES
			Author: Shay Levy
			Blog  : http://blogs.microsoft.co.il/blogs/ScriptFanatic/

		.LINK
			http://code.msdn.microsoft.com/PSClientManager

	#>
	
	
	[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
	
	param(
		[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[System.String]$Name,
		
		[switch]$Force,
		[switch]$NoRestart,
		[switch]$Quiet		
	)

	process
	{	
		try
		{
			$osgen = Get-OSGeneration
			
			if ($osgen -eq "8") {
				$dism = "DISM /Online /Enable-Feature /All /FeatureName:$Name"
			}
			else {
				$dism = "DISM /Online /Enable-Feature /FeatureName:$Name"
			}
			
			if($Quiet)	{$dism += " /Quiet"}
			if($NoRestart)	{$dism += " /NoRestart"}				

			if($Force -or $PSCmdlet.ShouldProcess($env:COMPUTERNAME,"Enable Feature '$Name'"))
			{
				Write-Verbose "CLI: $dism"
				if($Quiet)
				{
					$output = Invoke-Expression $dism
					if($LASTEXITCODE -eq 0)
					{
						$true
					}
					else
					{
						Write-Host $output
						Write-Error "Enabling feature $Name failed"
						$false
					}
				}
				else
				{
					Invoke-Expression $dism
				}
			}
		}
		catch
		{
			Throw
		}
	}
}

function getwindowsfeaturestate ([string] $featurename) {
	
	$installedvalue = $False;
			
	$check = Get-ClientFeature| Where-Object {$_.Name -like "$featurename"}

	if ($check) {
				
		if ($check.State -like "Disabled") {
			$installedvalue = $False;
		}
		elseif ($check.State -like "Enabled") {
			$installedvalue = $True;
		}
		else {
			throw "$featurename is in the unknown state $check.State";
			$installedvalue = $check.State;
		}	

	}
	else {
		write-host "$featurename is not available on this system" 
		$installedvalue = "notapplicable";
	}	

	return $installedvalue;
}

function set-windowsfeature ([string] $featurename){
	$state = getwindowsfeaturestate -featurename $featurename;
	
	write-host "Ensuring that the feature $featurename is enabled on this system"
	
	if ($state -like $False) {
		write-host "Enabling feature $featurename"
		Add-ClientFeature $featurename -Quiet -Force
						
		$timeout = new-timespan -Minutes 3
		$sw = [diagnostics.stopwatch]::StartNew()
		while ($sw.elapsed -lt $timeout){
		
			$newstate = getwindowsfeaturestate -featurename $featurename;
			
			if ($newstate -like $True){
				write-host "Feature $featurename is now enabled"
				return
			}
			else {
				write-host ".";
			}	
	 
			start-sleep -seconds 5
		}
 		
		throw "$featurename doesn't appear to be installed after waiting 5 minutes";								
	}
	elseif ($state -like "notapplicable") {		
		return 
	}
	elseif ($state -like $True) {
		write-host "$featurename is already enabled"
		return
	}
	else {
		throw "Unable to determine how to handle state $check";
	}
	
}

function Get-OSGeneration {
	if ([environment]::osversion.Version.Major -eq "6") {
		if ([environment]::osversion.Version.Minor -eq "1") {
			return "7";
		}
		elseif([environment]::osversion.Version.Minor -eq "2") {
			return "8";
		}	
	}
	else {
		return "unknown";		
	}
}

function Get-OSVersion {
	return [environment]::osversion.Version;		
}

Export-ModuleMember -function set-windowsfeature, Get-OSGeneration, Get-OSVersion
