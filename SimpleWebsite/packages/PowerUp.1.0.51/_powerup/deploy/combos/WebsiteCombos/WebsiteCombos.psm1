function Invoke-Combo-StandardWebsite($options)
{
	import-module -disablenamechecking powerupfilesystem
	import-module -disablenamechecking powerupweb
		
	# set up all the default options based on conventions - no actions yet taken
	ConfigureBasicDefaultOptions $options
	ConfigureApppoolDefaultOptions $options
	ConfigureBindingDefaultOptions $options
			
	if($options.stopwebsitefirst)
	{
		stop-apppoolandsite $options.websiteapppool.name $options.websitename
	}
	
	SetupAppPools $options
	SetupWebsite $options
	SetupBindings $options
	SetupVirtualDirectories $options
	
	if($options.startwebsiteafter)
	{
		start-apppoolandsite $options.websiteapppool.name $options.websitename
	}
}

function Invoke-Combo-RemoveStandardWebsite($options) {
	import-module -disablenamechecking powerupfilesystem
	import-module -disablenamechecking powerupweb
	
	# set up all the default options based on conventions - no actions yet taken
	ConfigureBasicDefaultOptions $options
	ConfigureApppoolDefaultOptions $options
	ConfigureBindingDefaultOptions $options
		
	RemoveAppFabricApplications $options
	RemoveVirtualDirectories $options
	RemoveWebsite $options
	RemoveAppPools $options
	
	
}

function ConfigureBasicDefaultOptions($options)
{
	if($options.stopwebsitefirst -eq $null)
	{
		$options.stopwebsitefirst = $true
	}
	
	if($options.startwebsiteafter -eq $null)
	{
		$options.startwebsiteafter = $true
	}
	
	if(!$options.port)
	{
		$options.port = 80
	}
		
	if (!$options.destinationfolder)
	{
		$options.destinationfolder = $options.websitename
	}

	if (!$options.sourcefolder)
	{
		$options.sourcefolder = $options.destinationfolder
	}
	
	if (!$options.fulldestinationpath)
	{
		$options.fulldestinationpath = "$($options.webroot)\$($options.destinationfolder)"
	}

	if (!$options.fullsourcepath)
	{
		$options.fullsourcepath = "$(get-location)\$($options.sourcefolder)"
	}
}

function ConfigureApppoolDefaultOptions($options)
{
	if (!$options.apppools)
	{

		if($options.apppool)
		{
			$firstapppool = $options.apppool
		}
		else
		{
			$firstapppool = @{}
		}
		$options.apppools = @($firstapppool)
	}
	
	
	foreach($apppool in $options.apppools)
	{
		if (!$apppool.executionmode)
		{
			$apppool.executionmode = "Integrated"
		}
		
		if(!$apppool.username)
		{
			$apppool.username = $apppool.identity
		}
		
		if (!$appool.dotnetversion)
		{
			$apppool.dotnetversion = "v4.0"
		}
		if (!$apppool.name)
		{
			$apppool.name = $options.websitename
		}
	}
	
	if($options.websiteapppoolname)
	{
		foreach($appool in $options.apppools)
		{
			if($options.websiteapppoolname -eq $apppool.name)
			{
				$options.websiteapppool = $appool
			}
		}
	}
	
	if(!$options.websiteapppool)
	{
		$options.websiteapppool = $options.apppools[0]
	}
}

function ConfigureBindingDefaultOptions($options)
{
	if (!$options.bindings)
	{
		$options.bindings = @(@{})
	}

	foreach($binding in $options.bindings)
	{
		if (!$binding.protocol)
		{
			$binding.protocol = "http"
		}

		if (!$binding.ip)
		{
			$binding.ip = "*"
		}
		
		if (!$binding.port)
		{
			if($binding.protocol -eq "https")
			{
				$binding.port = 443
			}
			else
			{
				$binding.port = 80
			}
		}
		
		if (!$binding.useselfsignedcert)
		{
			$binding.useselfsignedcert = $true
		}
		
		if (!$binding.certname)
		{
			$binding.certname = $options.websitename
		}
	}
}

function SetupAppPools($options)
{
	foreach($apppool in $options.apppools)
	{	
		set-webapppool $apppool.name $apppool.executionmode $apppool.dotnetversion $apppool.preserveexisting
		
		if ($apppool.username -eq "NT AUTHORITY\NETWORK SERVICE")
		{
			set-apppoolidentityType $apppool.name 2 #2 = NetworkService
		}
		elseif ($apppool.username)
		{
			set-apppoolidentitytouser $apppool.name $apppool.username $apppool.password
		}
	
		if($apppool.loaduserprofile -ne $null)
		{
			set-apppoolloaduserprofile $apppool.name ([System.Convert]::ToBoolean($apppool.loaduserprofile))
		}
	
		if($apppool.idletimeout -ne $null)
		{
			set-apppoolidletimeout $apppool.name ([System.Convert]::ToInt32($apppool.idletimeout))
		}
	}
}

function RemoveAppPools($options)
{
	import-module -disablenamechecking powerupweb

	foreach($apppool in $options.apppools)
	{	
		remove-webapppool-safe $apppool.name $apppool.executionmode $apppool.dotnetversion $apppool.preserveexisting		
		$apppool =  get-webapppool $($apppool.name)
		if (-not $apppool) { continue; }
		
		$defaultAppPools = ("DefaultAppPool") #add any more known default app pool names
		$isDefault = ($defaultAppPools -contains $($apppool.name))
		$isDefault = ($isDefault -or $($apppool.name).ToLower().StartsWith(".net"))
			
		#Special circumstance if we didn't remove the app-pool: remove if it's now "empty"
		#as it is now redundant: "Last one out closes the door behind them"
		if ($apppool -and !$isDefault) {			
			$appPoolHasApplications = get-apppoolhaschilditems $apppool.name
					
			if (!$appPoolHasApplications) {				
				Remove-WebAppPool-Safe $apppool.name $apppool.executionmode $apppool.dotnetversion $false
			}					
		}		
	}
}

function SetupVirtualDirectories($options)
{
	import-module -disablenamechecking powerupappfabric\ApplicationServer
	
	if($options.virtualdirectories)
	{
		foreach($virtualdirectory in $options.virtualdirectories)
		{
			write-host "Deploying virtual directory $($virtualdirectory.directoryname) to $($options.websitename)."
			
			if (!$virtualdirectory.fulldestinationpath) {
			
				if(!$virtualdirectory.destinationfolder) {
					$virtualdirectory.destinationfolder = $virtualdirectory.sourcefolder
				}
					
				$virtualdirectory.fulldestinationpath = "$($options.webroot)\$($virtualdirectory.destinationfolder)"
			}
			
			if (!$virtualdirectory.apppoolname) {
				$virtualdirectory.apppoolname = $options.websiteapppool.name
			}
			
			if ($virtualdirectory.fullsourcepath -or $virtualdirectory.sourcefolder)
			{		
				if (!$virtualdirectory.fullsourcepath) {
					$virtualdirectory.fullsourcepath = "$(get-location)\$($virtualdirectory.sourcefolder)"
				}
				
				if($virtualdirectory.copywithoutmirror)
				{
					copy-directory $virtualdirectory.fullsourcepath $virtualdirectory.fulldestinationpath
				}
				else
				{
					copy-mirroreddirectory $virtualdirectory.fullsourcepath $virtualdirectory.fulldestinationpath
				}			
			}
			
			if ($virtualdirectory.isapplication) {
				set-webapplication $options.websitename $virtualdirectory.apppoolname $virtualdirectory.directoryname $virtualdirectory.fulldestinationpath
			} else {
				set-virtualdirectory $options.websitename $virtualdirectory.directoryname $virtualdirectory.fulldestinationpath
			}
			
			if ($virtualdirectory.useapppool)
			{
				write-host "Switching virtual directory $($options.websitename)/$($virtualdirectory.directoryname) to use app pool identity for anonymous authentication."
				set-webproperty "$($options.websitename)/$($virtualdirectory.directoryname)" "/system.WebServer/security/authentication/AnonymousAuthentication" "username" ""
			}
			
			if ($virtualdirectory.appfabricautostart)
			{
				$hasAppFabric = HasAppFabricInstalled
				if (-not $hasAppFabric)
				{
					write-warning "Can't setup AppFabric applications as AppFabric is not installed"
				}
				else
				{
					write-host "Adding AppFabric auto-start to: $($options.websitename)/$($virtualdirectory.directoryname)"
					Set-ASApplication -SiteName $options.websitename -VirtualPath $virtualdirectory.directoryname -AutoStartMode All -EnableApplicationPool -Force | out-null
				}
			}
		}
	}
}

function RemoveVirtualDirectories($options)
{
	import-module -disablenamechecking powerupweb

	if($options.virtualdirectories)
	{
		foreach($virtualdirectory in $options.virtualdirectories)
		{
			write-host "Removing virtual directory $($virtualdirectory.directoryname) from $($options.websitename)."
			
			if (!$virtualdirectory.fulldestinationpath) {
			
				if(!$virtualdirectory.destinationfolder) {
					$virtualdirectory.destinationfolder = $virtualdirectory.sourcefolder
				}
					
				$virtualdirectory.fulldestinationpath = "$($options.webroot)\$($virtualdirectory.destinationfolder)"
			}
			
			if (!$virtualdirectory.apppoolname) {
				$virtualdirectory.apppoolname = $options.websiteapppool.name
			}				
			
			if ($virtualdirectory.isapplication) {
				remove-webapplication-safe $options.websitename $virtualdirectory.apppoolname $virtualdirectory.directoryname $virtualdirectory.fulldestinationpath
			} else {
				remove-virtualdirectory-safe $options.websitename $virtualdirectory.directoryname $virtualdirectory.fulldestinationpath
			}

			Remove-Directory $virtualdirectory.fulldestinationpath			
		}
	}
}

function SetupBindings($options)
{
	foreach($binding in $options.bindings)
	{
		if($binding.protocol -eq "https")
		{
			Set-WebsiteForSsl $binding.useselfsignedcert $options.websitename $binding.certname $binding.ip $binding.port $binding.url		
		}
		else
		{
			set-websitebinding $options.websitename $binding.url $binding.protocol $binding.ip $binding.port
		}
	}
}

function SetupWebsite($options)
{
	if($options.copywithoutmirror)
	{
		copy-directory $options.fullsourcepath $options.fulldestinationpath -preserveexisting $options.preserveexistingwebsite
	}
	else
	{
		copy-mirroreddirectory $options.fullsourcepath $options.fulldestinationpath
	}

	$firstBinding = $options.bindings[0]
	
	set-website $options.websitename $options.websiteapppool.name $options.fulldestinationpath $firstBinding.url $firstBinding.protocol $firstBinding.ip $firstBinding.port $options.preserveexistingwebsite
}

function RemoveWebsite($options)
{			
	import-module -disablenamechecking powerupfilesystem
	import-module -disablenamechecking webadministration
	import-module -disablenamechecking powerupweb

	remove-WebSite-safe $options.websitename $options.preserveexistingwebsite
	
	$forceRemove = $false
	$website = Get-Website -Name $options.websitename	
	$defaultWebSites = ("Default Web Site") #add any more known default website names, comma-separated
	$isDefault = ($defaultWebSites -contains $($options.websitename))
	
	#Special circumstance if we didn't remove the website: remove if it's now "empty"
	#as it was probably just a container website for virtual directories:
	#"Last one out closes the door behind them"
	if ($website -and !$isDefault) {
		$rootFolderEmpty = Get-IsEmptyDirectory $options.fulldestinationpath
		$websiteHasChildren = get-websitehaschilditems $options.websitename
				
		if ($rootFolderEmpty -and !$websiteHasChildren) {
			$forceRemove = $true
			remove-WebSite-safe $options.websitename $false
		}	
	}
	
	if ($forceRemove -or !$options.preserveexistingwebsite) {
		Remove-Directory $options.fulldestinationpath
	}
}

function HasAppFabricInstalled()
{
	$IISService = Get-Service -Name 'W3SVC' -ErrorAction SilentlyContinue
	if(-not $IISService) {		
		return $false;
	}
	 
	$AppFabricMonitoringService = Get-Service -Name 'AppFabricEventCollectionService' -ErrorAction SilentlyContinue
	if(-not $AppFabricMonitoringService) {		
		return $false;
	}
	 
	$AppFabricMonitoringService = Get-Service -Name 'AppFabricWorkflowManagementService' -ErrorAction SilentlyContinue
	if(-not $AppFabricMonitoringService) {		
		return $false;
	}
	
	return $true;
}

#TODO: Check this - no appfabric applications for now, so hard to test
function RemoveAppFabricApplications($options)
{
	import-module -disablenamechecking powerupappfabric\ApplicationServer

	if($options.appfabricapplications)
	{
		$hasAppFabric = HasAppFabricInstalled
		if (-not $hasAppFabric) {
			write-warning "Can't remove AppFabric applications as AppFabric is not installed"
			return;
		}
	
		foreach($application in $options.appfabricapplications)
		{
			write-host "Removing AppFabric application from $options.websitename, virtual dir $application.virtualdirectory."		
			Set-ASApplication -SiteName $options.websitename -VirtualPath $application.virtualdirectory -AutoStartMode Disable -Force			
		}
	}
}