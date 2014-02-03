function Set-Permissions
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be granted.  Can be a file system or registry path.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user or group getting the permissions
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        # The permission: e.g. FullControl, Read, etc.  For file system items, use values from [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).  For registry items, use values from [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        $Permissions,
              		
		$InheritanceFlags = [Security.AccessControl.InheritanceFlags]::None,
		$PropagationFlags = [Security.AccessControl.PropagationFlags]::None,
				
        [Switch]
        # Removes all non-inherited permissions on the item.
        $Clear
    )
    	
    $Path = Resolve-Path $Path
    
    $pathQualifier = Split-Path -Qualifier $Path
    if( -not $pathQualifier )
    {
        throw "Unable to get qualifier on path $Path. No permissions granted."
    }
    $pathDrive = Get-PSDrive $pathQualifier.Trim(':')
    $pathProvider = $pathDrive.Provider
    $providerName = $pathProvider.Name
    if( $providerName -ne 'Registry' -and $providerName -ne 'FileSystem' )
    {
        throw "Unsupported path: '$Path' belongs to the '$providerName' provider."
    }

    $rights = 0
	$Permissions | ForEach-Object {

        $right = ($_ -as "Security.AccessControl.$($providerName)Rights")
        if( -not $right )
        {
            throw "Invalid $($providerName)Rights: $_.  Must be one of $([Enum]::GetNames("Security.AccessControl.$($providerName)Rights"))."
        }
        $rights = $rights -bor $right
    }
    
    Write-Host "Granting $Identity $Permissions on $Path."
	
    # We don't use Get-Acl because it returns the whole security descriptor, which includes owner information.
    # When passed to Set-Acl, this causes intermittent errors.  So, we just grab the ACL portion of the security descriptor.
    # See http://www.bilalaslam.com/2010/12/14/powershell-workaround-for-the-security-identifier-is-not-allowed-to-be-the-owner-of-this-object-with-set-acl/
    $currentAcl = (Get-Item $Path).GetAccessControl("Access")
        
    $accessRule = New-Object "Security.AccessControl.$($providerName)AccessRule" $identity,$rights,$InheritanceFlags,$PropagationFlags,"Allow"
    if( $Clear )
    {
        $rules = $currentAcl.Access |
                    Where-Object { -not $_.IsInherited }
        
        if( $rules )
        {
            $rules | 
                ForEach-Object { [void] $currentAcl.RemoveAccessRule( $_ ) }
        }
    }
    $currentAcl.SetAccessRule( $accessRule )
    Set-Acl $Path $currentAcl
}

function set-right($right, $user=$null)
{

	if($user) {
		write-host "Granting $user the $right right"
		$output = & "$PSScriptRoot\ntrights.exe" +r $right -u $user
	}
	else {
		write-host "Granting current user the $right right"
		$output = & "$PSScriptRoot\ntrights.exe" +r $right
	}
	
	if ($lastexitcode -ne 0)
	{
		write-error $output[0]
		throw "Set of right $right failed"
	}	

}

function Test-CurrentUserInAdministratorRole {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
        return $principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )
    } catch {
        throw "Failed to determine if the current user has elevated privileges. The error was: '{0}'." -f $_
	}
}

export-modulemember -function set-permissions, Test-CurrentUserInAdministratorRole, set-right
