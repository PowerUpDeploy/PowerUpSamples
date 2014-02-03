#NOTE: comspec environment variable points to location of cmd.exe which is in system32 folder - same as netsh.exe

function Set-InboundRuleLegacy
{
    param
    (
	    [string] $Name = $(throw 'Must provide a rule name'),
        [int] $Port = $(throw 'Must provide a port to open')        
    ) 
    
	try{
		Write-Host "Creating firewall rule $Name for port $Port"		
		$comspec = $env:ComSpec
		$netshExe = (Split-Path $comspec -parent) + "\netsh.exe"	
		$output = & $netshExe firewall add portopening TCP $Port "$Name";			
		write-host $output
	}
	catch{		
		throw "Could not create firewall rule $Name for port $Port"
	}	
}

function Set-InboundRule
{
    param
    (
	    [string] $Name = $(throw 'Must provide a rule name'),
        [int] $Port = $(throw 'Must provide a port to open')        
    ) 
    
	try{
		Write-Host "Creating firewall rule $Name for port $Port"
		$comspec = $env:ComSpec
		$netshExe = (Split-Path $comspec -parent) + "\netsh.exe"	
		$output = & $netshExe advfirewall firewall add rule name="$Name" protocol=TCP dir=in localport="$Port" action=allow				
		write-host $output
	}
	catch{		
		throw "Could not create firewall rule $Name for port $Port"
	}	
}