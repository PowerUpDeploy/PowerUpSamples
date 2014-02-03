$iisPath = "IIS:\"
$sitesPath = "IIS:\sites"
$appPoolsPath = "IIS:\apppools"
$bindingsPath = "IIS:\sslbindings"



$ModuleName = "WebAdministration"
$ModuleLoaded = $false
$LoadAsSnapin = $false

if ($PSVersionTable.PSVersion.Major -ge 2)
{
    if ((Get-Module -ListAvailable | ForEach-Object {$_.Name}) -contains $ModuleName)
    {
        Import-Module -disablenamechecking $ModuleName
        if ((Get-Module | ForEach-Object {$_.Name}) -contains $ModuleName)
        {
            $ModuleLoaded = $true
        }
        else
        {
            $LoadAsSnapin = $true
        }
    }
    elseif ((Get-Module | ForEach-Object {$_.Name}) -contains $ModuleName)
    {
        $ModuleLoaded = $true
    }
    else
    {
        $LoadAsSnapin = $true
    }
}
else
{
    $LoadAsSnapin = $true
}

if ($LoadAsSnapin)
{
    if ((Get-PSSnapin -Registered | ForEach-Object {$_.Name}) -contains $ModuleName)
    {
        Add-PSSnapin $ModuleName
        if ((Get-PSSnapin | ForEach-Object {$_.Name}) -contains $ModuleName)
        {
            $ModuleLoaded = $true
        }
    }
    elseif ((Get-PSSnapin | ForEach-Object {$_.Name}) -contains $ModuleName)
    {
        $ModuleLoaded = $true
    }
}


function StopAppPoolAndSite($appPoolName, $siteName)
{
	StopAppPool($appPoolName)
	StopSite($siteName)
}

function StartAppPoolAndSite($appPoolName, $siteName)
{
	StartSite($siteName)
	StartAppPool($appPoolName)
}

function StopSite($siteName)
{	
	StopWebItem $sitesPath $siteName
}

function StopAppPool($appPoolName)
{	
	StopWebItem $appPoolsPath $appPoolName
}

function StartSite($siteName)
{	
	StartWebItem $sitesPath $siteName
}

function StartAppPool($appPoolName)
{	
	StartWebItem $appPoolsPath $appPoolName
}

function CreateAppPool($appPoolName)
{	
	if (!(WebItemExists $appPoolsPath $appPoolName))
	{
		New-WebAppPool $appPoolName | out-null
	}
}

function DeleteAppPool($appPoolName)
{	
	if (WebItemExists $appPoolsPath $appPoolName)
	{
		Remove-WebAppPool $appPoolName | out-null
	}
}

function DeleteWebsite($websiteName)
{	
	if (WebItemExists $sitesPath $websiteName)
	{
		Remove-WebSite $websiteName | out-null
	}
}

function SetAppPoolManagedPipelineMode($appPool, $pipelineMode)
{
	$appPool.managedPipelineMode = $pipelineMode
}

function SetAppPoolManagedRuntimeVersion($appPool, $runtimeVersion)
{
	$appPool.managedRuntimeVersion = $runtimeVersion
}

function CreateWebsite($websiteName, $appPoolName, $fullPath, $protocol, $ip, $port, $hostHeader, $nondestructive)
{		
	if (WebItemExists $sitesPath $websiteName -and $nondestructive)
	{
		return
	}
	else
	{
		New-Item $sitesPath\$websiteName -physicalPath $fullPath -applicationPool $appPoolName -bindings @{protocol="$protocol";bindingInformation="${ip}:${port}:${hostHeader}"} | out-null
	}
}

function Set-WebsiteForSsl($useSelfSignedCert, $websiteName, $certificateName, $ipAddress, $port, $url)
{
	if ([System.Convert]::ToBoolean($useSelfSignedCert))
	{
		write-host "set-selfsignedsslcertificate ${certificateName}"
		set-selfsignedsslcertificate ${certificateName}
	}
		
	set-sslbinding $certificateName $ipAddress $port
	set-websitebinding $websiteName $url "https" $ipAddress $port 
}

function GetSslCertificate($certName)
{
	if ($certName.StartsWith("*")) {
		#escape the leading asterisk which breaks the regex below (-match ....)
		$certName = "\" + $certName
	}
	Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.FriendlyName -match "${certName}" -or $_.Subject -match "${certName}"} | Select-Object -First 1
}


function Test-SslBindingExists($ip, $port)
{
	return ((dir $bindingsPath | Where-Object {($_.Port -eq $port) -and ($_.IPAddress -contains $ip)}) | measure-object).Count -gt 0
}

function Test-WebsiteHasSslBinding($websiteName)
{
	return [bool](dir $bindingsPath `
			| % { $_.Sites }`
			| % { $_.Value -eq $websiteName }`
			| Where-Object { $_ -eq $true })
}

function CreateSslBinding($certificate, $ip, $port)
{
	$existingPath = get-location
	set-location $bindingsPath
	
	$certificate | new-item "${ip}!${port}" | out-null
	set-location $existingPath
}


function StopWebItem($itemPath, $itemName)
{
	if (WebItemExists $itemPath $itemName)
	{
		$item = Get-WebItemState $itemPath\$itemName -ErrorAction SilentlyContinue
		if (-not $item) { return; }
		$state = ($item).Value
		if ($state -eq "started")
		{
			Stop-WebItem $itemPath\$itemName | out-null
		}
	}
}

function get-webapppool($appPoolName) {
	return get-item "$appPoolsPath\$appPoolName" -ErrorAction SilentlyContinue
}

function set-webapppool32bitcompatibility($appPoolName, $enabled = "true")
{
	$appPool = Get-Item $appPoolsPath\$appPoolName
	$appPool.enable32BitAppOnWin64 = $enabled
	$appPool | set-item | out-null
}

function add-websitetoapppool($websiteName, $appPoolName) {
	Set-ItemProperty $sitesPath\$websiteName ApplicationPool $appPoolName
}

function SetAppPoolProperties($appPoolName, $pipelineMode, $runtimeVersion)
{
	$appPool = Get-Item $appPoolsPath\$appPoolName
	SetAppPoolManagedPipelineMode $appPool $pipelineMode
	SetAppPoolManagedRuntimeVersion $appPool $runtimeVersion
	
	$appPool | set-item | out-null
}
 

function StartWebItem($itemPath, $itemName)
{
	if (WebItemExists $itemPath $itemName)
	{
		$state = (Get-WebItemState $itemPath\$itemName).Value
		if ($state -eq "stopped")
		{
			Start-WebItem $itemPath\$itemName
		}
	}
}

function WebItemExists($rootPath, $itemName)
{
	return ((dir $rootPath | ForEach-Object {$_.Name}) -eq $itemName)	
}

function ChildWebItemsExist($rootPath, $itemName)
{	
	return ([bool](dir $rootPath\$itemName))
}

function ChildAppPoolItemsExist($rootPath, $itemName)
{    
	return ([bool](dir $sitesPath | ForEach-Object { get-item "$sitesPath\\$($_.Name)" | Select-Object applicationPool  | ForEach-Object { $($_).applicationPool -eq $itemName } | Where-Object { $_ -eq $true }  }))
}

function Remove-WebAppPool-Safe($appPoolName, $nondestructive=$false)
{
	if (-not $nondestructive) {
		write-host "Removing apppool $appPoolName"
		DeleteAppPool $appPoolName
	} else {
		write-host "Preserving apppool $appPoolName"
	}
}

function set-WebAppPool($appPoolName, $pipelineMode, $runtimeVersion, $nondestructive=$false)
{
	write-host "Ensuring apppool $appPoolName with pipeline mode $pipelineMode and .Net version $runtimeVersion"
	if (WebItemExists $appPoolsPath $appPoolName -and $nondestructive)
	{
		DeleteAppPool $appPoolName
	}
	CreateAppPool $appPoolName
	
	SetAppPoolProperties $appPoolName $pipelineMode $runtimeVersion
}

function Remove-WebSite-Safe($websiteName, $nondestructive=$false)
{
	if(!$nondestructive)
	{
		write-host "Removing website $websiteName"
		DeleteWebsite $websiteName
	} else {
		write-host "Preserving website $websiteName"
	}
}

function set-WebSite($websiteName, $appPoolName, $fullPath, $hostHeader, $protocol="http", $ip="*", $port="80", $nondestructive=$false)
{
	write-host "Ensuring there is website $websiteName with path $fullPath, app pool $apppoolname, bound to to host header $hostHeader with IP $ip, port $port over $protocol"
	if(!$nondestructive)
	{
		DeleteWebsite $websiteName
	}
	CreateWebsite $websiteName $appPoolName $fullPath $protocol $ip $port $hostHeader $nondestructive
}

function get-websitehaschilditems($websiteName)
{
	if (!(WebItemExists $sitesPath $websiteName)) {
		return $false;
	}
	return ChildWebItemsExist $sitesPath $websiteName
}

function get-apppoolhaschilditems($appPoolName)
{
	if (!(WebItemExists $appPoolsPath $appPoolName)) {
		return $false;
	}
	return ChildAppPoolItemsExist $appPoolsPath $appPoolName
}

function set-SelfSignedSslCertificate($certName)
{	
	write-host "Ensuring existance of self signed ssl certificate $certName"
	if(!(GetSslCertificate $certName))
	{
		write-host "Creating self signed ssl certificate $certName"
		$output = & "$PSScriptRoot\makecert.exe" -r -pe -n "CN=${certName}" -b 07/01/2008 -e 07/01/2020 -eku 1.3.6.1.5.5.7.3.1 -ss my -sr localMachine -sky exchange -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12
	}
}
function EnsureSelfSignedSslCertificate($certName)
{	
	if(!(GetSslCertificate $certName))
	{
		$output = & "$PSScriptRoot\makecert" -r -pe -n "CN=${certName}" -b 07/01/2008 -e 07/01/2020 -eku 1.3.6.1.5.5.7.3.1 -ss my -sr localMachine -sky exchange -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12
	}
}

function Set-WebSiteBinding($websiteName, $hostHeader, $protocol="http", $ip="*", $port="80")
{
	$existingBinding = get-webbinding -Name $websiteName -IP $ip -Port $port -Protocol $protocol -HostHeader $hostHeader
	
	if(!$existingBinding)
	{
		new-websitebinding $websiteName $hostHeader $protocol $ip $port 
	}
}

function New-WebSiteBinding($websiteName, $hostHeader, $protocol="http", $ip="*", $port="80")
{
	write-host "Binding website $websiteName to host header $hostHeader with IP $ip, port $port over $protocol"
	New-WebBinding -Name $websiteName -IP $ip -Port $port -Protocol $protocol -HostHeader $hostHeader
}

function New-WebSiteBindingNonHttp($websiteName, $protocol, $bindingInformation)
{
	write-host "Binding website $websiteName to binding information $bindingInformation over $protocol"
	New-ItemProperty $sitesPath\$websiteName –name bindings –value @{protocol="$protocol";bindingInformation="$bindingInformation"} | out-null
}

function Set-SslBinding($certName, $ip, $port)
{
	write-host "Binding certifcate $certName to IP $ip, port $port"
	$certificate = GetSslCertificate $certName
	
	if (!$certificate) {throw "Certificate for site $certName not in current store"}

	if($ip -eq "*") {$ip = "0.0.0.0"}
	
	if(!(Test-SslBindingExists $ip $port))
	{
		CreateSslBinding $certificate $ip $port
	}
}

function new-virtualdirectory($websiteName, $subPath, $physicalPath)
{
	write-host "Adding virtual directory $subPath to web site $websiteName pointing to $physicalPath"
	New-Item $sitesPath\$websiteName\$subPath -physicalPath $physicalPath -type VirtualDirectory | out-null
}

function set-virtualdirectory($websiteName, $subPath, $physicalPath)
{
	if (WebItemExists $sitesPath\$websiteName $subPath)
	{
		remove-webvirtualdirectory -Name $subPath -Site $websiteName
	}

	new-virtualdirectory $websiteName $subPath $physicalPath
}

function remove-virtualdirectory-safe($websiteName, $subPath, $physicalPath)
{
	if (WebItemExists $sitesPath\$websiteName $subPath)
	{
		remove-webvirtualdirectory -Name $subPath -Site $websiteName
	}
}

function new-webapplication($websiteName, $appPoolName, $subPath, $physicalPath)
{
	write-host "Adding application $subPath to web site $websiteName pointing to $physicalPath running under app pool  $appPoolName"
	New-Item $sitesPath\$websiteName\$subPath -physicalPath $physicalPath -applicationPool $appPoolName -type Application | out-null
}

function set-webapplication($websiteName, $appPoolName, $subPath, $physicalPath)
{
	if (WebItemExists $sitesPath\$websiteName $subPath)
	{
		remove-webapplication -Name $subPath -Site $websiteName
	}
	
	new-webapplication $websiteName $appPoolName $subPath $physicalPath
}

function remove-webapplication-safe($websiteName, $appPoolName, $subPath, $physicalPath)
{
	if ((WebItemExists $sitesPath $websiteName) -and (WebItemExists $sitesPath\$websiteName $subPath))
	{		
		remove-webapplication -Name $subPath -Site $websiteName
	}
}

function Stop-AppPool($appPoolName)
{
	write-host "Stopping app pool $appPoolName"
	StopAppPool($appPoolName)	
}

function Stop-AppPoolAndSite($appPoolName, $siteName)
{
	write-host "Stopping app pool $appPoolName and site $siteName"
	StopAppPool($appPoolName)
	StopSite($siteName)
}

function Start-AppPool($appPoolName)
{
	write-host "Starting app pool $appPoolName"
	StartAppPool($appPoolName)
}

function Start-AppPoolAndSite($appPoolName, $siteName)
{
	write-host "Starting app pool $appPoolName and site $siteName"
	StartSite($siteName)
	StartAppPool($appPoolName)
}

function set-apppoolidentitytouser($appPoolName, $userName, $password)
{
	write-host "Setting $appPoolName to be run under the identity $userName"
	$appPool = Get-Item $appPoolsPath\$appPoolName
	$appPool.processModel.username =  $userName
	$appPool.processModel.password = $password
	$appPool.processModel.identityType = 3
	$appPool | set-item| out-null
}

function set-apppoolidentityType($appPoolName, [int]$identityType)
{
	write-host "Setting $appPoolName to be run under the identityType $identityType"
	$appPool = Get-Item $appPoolsPath\$appPoolName
	$appPool.processModel.identityType = $identityType
	$appPool | set-item| out-null
}

function set-apppoolstartMode($appPoolName, [int]$startMode)
{
	write-host "Setting $appPoolName to be run with startMode $startMode"
	$appPool = Get-Item $appPoolsPath\$appPoolName
	$appPool.startMode = $startMode
	$appPool | set-item| out-null
}

function set-apppoolloaduserprofile($appPoolName, [bool]$loadUserProfile)
{
	write-host "Setting $appPoolName LoadUserProfile to $loadUserProfile"
	$appPool = Get-Item $appPoolsPath\$appPoolName
	$appPool.processModel.loadUserProfile = $loadUserProfile
	$appPool | set-item| out-null
}

function set-apppoolidletimeout($appPoolName, [int]$idleTimeoutMinutes)
{
	write-host "Setting $appPoolName idle timeout to $idleTimeoutMinutes"
	$appPool = Get-Item $appPoolsPath\$appPoolName
	$appPool.processModel.idleTimeout = [TimeSpan]::FromMinutes($idleTimeoutMinutes)
	$appPool | set-item| out-null
}

function set-property($applicationPath, $propertyName, $value)
{
	Set-ItemProperty $sitesPath\$applicationPath -name $propertyName -value $value
}

function set-webproperty($websiteName, $propertyPath, $property, $value)
{
	Set-WebConfigurationProperty -filter $propertyPath -name $property -value $value -location $websiteName
}

function enable-aspnetisapi($isapiPath){  

  $isapiConfiguration = get-webconfiguration "/system.webServer/security/isapiCgiRestriction/add[@path='$isapiPath']/@allowed"  

  if (!$isapiConfiguration.value){  
	   set-webconfiguration "/system.webServer/security/isapiCgiRestriction/add[@path='$isapiPath']/@allowed" -value "True" -PSPath:$iisPath   
  }  
 }  

 function enable-featuredelegation($sectionName) 
{
	write-host "Enabling feature delegation for $sectionName"
	
	Set-WebConfiguration //System.webServer/$sectionName -metadata overrideMode -value Allow -PSPath IIS:/
}
 
function set-WebConfigurationPropertyIfRequired($xpath, $propertyName, [string]$value, $appPath)
{
	try
	{
		[string] $existingValue = (get-webconfigurationproperty -Filter $xpath -name $propertyName -PsPath $iisPath -Location $appPath).Value
	}catch{
        $existingValue = $false
    }

	if(($existingValue -ne $value))
	{
		write-host "Setting value $xpath $propertyName $value"        
		Set-WebConfigurationProperty -Filter $xpath -name $propertyName -Value $value -PsPath $iisPath -Location $appPath
	}
}
 
function set-anonymousauthentication($appPath, $value) 
{
	set-WebConfigurationPropertyIfRequired "/system.webServer/security/authentication/anonymousAuthentication" "enabled" $value $appPath
}

function set-windowsauthentication($appPath, $value) 
{
	Set-WebConfigurationPropertyIfRequired "/system.webServer/security/authentication/windowsAuthentication" "enabled" $value  $appPath
}

function set-requiressl($appPath, $value) {
	Set-WebConfigurationPropertyIfRequired "/system.webServer/security/access" "sslflags" $value $appPath 
}

function protect-webconfig($physicalWebConfigFolderPath, $configFileName="web.config")
{
	if($configFileName -ne "web.config") {
		write-host "Renaming file $physicalWebConfigFolderPath\$configFileName to web.config"
		Rename-Item $physicalWebConfigFolderPath\$configFileName web.config
	}
	
	write-host "Encrypting config file for path $physicalWebConfigFolderPath"

	$regiis = $env:WINDIR + "\Microsoft.NET\\Framework\\v4.0.30319\\aspnet_regiis"
	$path = $physicalWebConfigFolderPath
	
	$output = & $regiis -pef connectionStrings $path 
	
	if($configFileName -ne "web.config") {
		write-host "Renaming file $physicalWebConfigFolderPath\$configFileName back from web.config"
		Rename-Item $physicalWebConfigFolderPath\web.config $configFileName 
	}
	
	if ($lastexitcode -ne 0)
	{
		write-host $output
		throw "Unable to encrypt web.config file contained within folder $physicalWebConfigFolderPath"
	}
}

function enable-aspnet()
{
	write-host "Registering asp.net with IIS"

	$regiis = $env:WINDIR + "\Microsoft.NET\\Framework\\v4.0.30319\\aspnet_regiis"
	
	$output = & $regiis -iru
	
	if ($lastexitcode -ne 0)
	{
		write-host $output
		throw "Unable to register asp.net with IIS"
	}
}
 
function Open-WebChangeTransaction()
{
	return Begin-WebCommitDelay
}

function Close-WebChangeTransaction()
{
	return End-WebCommitDelay
}

export-modulemember -function enable-featuredelegation, set-anonymousauthentication, set-windowsauthentication, enable-aspnet, protect-webconfig, enable-aspnetisapi, set-requiressl, set-webapppool32bitcompatibility, set-apppoolidentitytouser, set-apppoolidentityType, set-apppoolstartMode, set-apppoolloaduserprofile, set-apppoolidletimeout, new-webapplication, set-webapplication, remove-webapplication-safe, new-virtualdirectory, set-virtualdirectory, remove-virtualdirectory-safe, start-apppoolandsite, start-apppool, start-site, stop-apppool, stop-apppoolandsite, set-website, remove-website-safe, set-webapppool, remove-webapppool-safe, set-websitebinding, New-WebSiteBinding, New-WebSiteBindingNonHttp, set-SelfSignedSslCertificate, set-sslbinding, Set-WebsiteForSsl, set-property, set-webproperty, open-WebChangeTransaction, close-WebChangeTransaction, get-websitehaschilditems, get-apppoolhaschilditems, get-webapppool, add-websitetoapppool, Test-SslBindingExists, Test-WebsiteHasSslBinding