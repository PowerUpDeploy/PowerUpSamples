function Set-ServiceCredentials
{
    param
    (
        [string] $Name = $(throw 'Must provide a service name'),
        [string] $Username = $(throw "Must provide a username"),
        [string] $Password
    ) 
    
	if (!($Username.Contains("\")))
	{
        $Username = "$env:COMPUTERNAME\$Username"
    }
    
    $service = gwmi win32_service -filter "name='$Name'"
	if ($service -ne $null)
	{
        $params = $service.psbase.getMethodParameters("Change");
        $params["StartName"] = $Username
		
		if($Password) {
			$params["StartPassword"] = $Password
		}
		
        $service.invokeMethod("Change", $params, $null) | out-null

		Write-Output "Credentials changed for service '$Name'"
	}
	else
	{
		throw "Could not find service '$Name' for which to change credentials"
	}
}

function Set-ServiceStartMode
{
    param
    (
        [string] $Name = $(throw 'Must provide a service name'),
        [string] $Mode = $(throw 'Must provide a new start mode')
    ) 
        
    $service = gwmi win32_service -filter "name='$Name'"
	if ($service -ne $null)
	{
        $params = $service.psbase.getMethodParameters("Change");
        $params["StartMode"] = $Mode
        $service.invokeMethod("Change", $params, $null) | out-null

		Write-Output "Start mode change to '$Mode' for service '$Name'"
	}
	else
	{
		throw "Could not find service '$Name' for which to change start mode"
	}
}

function Set-ServiceFailureOptions
{
    param
    (
        [string] $Name = $(throw 'Must provide a service name'),
        [int] $ResetDays,
        [string] $Action,
        [int] $DelayMinutes
    ) 
    	
	$ResetSeconds = $($ResetDays*60*60*24)
	$DelayMilliseconds = $($DelayMinutes*1000*60)
	$Action = "restart"
	$Actions = "$Action/$DelayMilliseconds/$Action/$DelayMilliseconds/$Action/$DelayMilliseconds"
		
	write-host "Setting service failure options for service $Name to reset after $ResetDays days, and $Action after $DelayMinutes minutes"
	
	$output = & sc.exe failure $Name reset= $ResetSeconds actions= $Actions
}

function Get-SpecificService
{
	param
    (
        [string] $Name = $(throw 'Must provide a service name')
    )
	
	return Get-Service | Where-Object {$_.Name -eq $Name}
}	
	
function Stop-MaybeNonExistingService
{
	param
    (
        [string] $Name = $(throw 'Must provide a service name'),
		[bool] $force = $false
    ) 

	$serviceExists = !((Get-Service | Where-Object {$_.Name -eq $Name}) -eq $null)
	
	if ($serviceExists) {	
		Write-Host "Stopping service $Name"
		$ServiceNamePID  = Get-Service -Name $Name				
		$ServicePID = (get-wmiobject win32_Service | Where { $_.Name -eq $ServiceNamePID.Name }).ProcessId		
			
		if ($force) {
			Stop-Service $Name -Force
		} else {
			Stop-Service $Name
		}

		#Back-up "nuclear option" - attempt to kill the process.  This removes anything that might be locking the parent folder etc
		if ($ServicePID -gt 0) {
			Stop-Process $ServicePID -force -ErrorAction SilentlyContinue
		}
	}
	else
	{
		Write-Host "$Name Service is not installed, so cannot be stopped"
	}
}

function Start-MaybeNonExistingService
{
	param
    (
        [string] $Name = $(throw 'Must provide a service name')
    ) 

	$serviceExists = !((Get-Service | Where-Object {$_.Name -eq $Name}) -eq $null)
	
	if ($serviceExists) {	
		Write-Host "Starting service $Name"
		Start-Service $Name
	}
	else
	{
		Write-Host "$Name Service is not installed, so cannot be started"
	}
}

function Remove-MaybeNonExistingService
{
	param
	(
		[string] $Name = $(throw 'Must provide a service name')		
	)

	$serviceExists = !((Get-Service | Where-Object {$_.Name -eq $Name}) -eq $null)
	
	if ($serviceExists) {			
		Remove-Service $Name		
	}
	else
	{
		Write-Host "$Name Service is not installed, so cannot be removed"
	}	
}

function Remove-Service 
{
	param
	(
		[string] $Name = $(throw 'Must provide a service name')		
	) 

	$serviceExists = !((Get-Service | Where-Object {$_.Name -eq $Name}) -eq $null)
		
	if ($serviceExists) {
		Write-Host "Uninstalling $Name"

		Stop-MaybeNonExistingService $Name			
		$output = & sc.exe delete "$Name" 
		
		if ($lastexitcode -ne 0)
		{
			write-error $output[0]
			throw "Unable to remove service $Name"
		}
			
	}
}

function Set-Service
{
	param
    (
        [string] $Name = $(throw 'Must provide a service name'),		
		[string] $InstallPath = $(throw 'Must provide an install path'),
		[string] $ExeFileName = $(throw 'Must provide an exe file name'),
		[string] $DisplayName = $null,
		[string] $Description = $null,
		[string] $StartupType = "auto",
		[string] $Dependencies = $null
    ) 

	Remove-Service $Name
		
	Write-Host "Installing service $Name"
	$binPath = "$InstallPath\$ExeFileName"
	if ($DisplayName) {
		$output = & sc.exe create "$Name" binPath= "$binPath" start= $StartupType DisplayName= "$DisplayName"
	} else {
		$output = & sc.exe create "$Name" binPath= "$binPath" start= $StartupType
	}
	
	if ($Description) {
		$output += & sc.exe description "$Name" "$Description"
	}
	
	if ($Dependencies) {
		$output += & sc.exe config "$Name" depend= "$Dependencies"
	}
}

function Set-ServiceDependencies([string]$Name, [string]$Dependencies)
{
	$output = & sc.exe config "$Name" depend= "$Dependencies"
}
