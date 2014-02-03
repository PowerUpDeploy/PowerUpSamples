function New-Share($Path, $Name) {
		try {
			$ErrorActionPreference = 'Stop'
			if ( (Test-Path $Path) -eq $false) {
				$null = New-Item -Path $Path -ItemType Directory
			}
			net share $Name=$Path
		}
		catch {
			Write-Warning "Create a new share: Failed, $_"
		}
}
export-modulemember -function New-Share