param([string]$deployFile = ".\deploy.ps1", [string]$deploymentProfile, $tasks="default", [hashtable] $parameters = @{})

try {
	$ErrorActionPreference='Stop'

	write-host "Deploying package using profile $deploymentProfile"	
	write-host "Deployment being run under account $env:username"

	write-host "Importing basic modules required by PowerUp"
	$currentPath = Get-Location
	$env:PSModulePath = $env:PSModulePath + ";$currentPath\_powerup\deploy\core\" + ";$currentPath\_powerup\deploy\modules\" + ";$currentPath\_powerup\deploy\combos\"

	import-module psake.psm1
	$msgs.build_success = 'Deployment succeeded'		
			
	write-host "Calling psake with deployment file $deployFile "
	$psake.use_exit_on_error = $true
	$psakeParameters = @{"deployment.profile"=$deploymentProfile; "deployment.parameters"=$parameters}
	invoke-psake $deployFile $tasks -parameters $psakeParameters
if (-not $psake.build_success) {
        $host.ui.WriteErrorLine("Build Failed!")
        $ExitCode = 1
    }
    else {
        $ExitCode = $LastExitCode
    }}
finally {
    write-host "Exiting with exit code: $ExitCode"
    try {
        remove-module psake
    }
    catch{}
  
    exit $ExitCode
}