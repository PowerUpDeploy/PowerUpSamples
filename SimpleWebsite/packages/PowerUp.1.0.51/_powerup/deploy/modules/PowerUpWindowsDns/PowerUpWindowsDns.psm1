function Add-HostsEntry([string]$ip, [string]$hostname) {
	$hostsFile = "$env:windir\System32\drivers\etc\hosts"
	Remove-HostsEntry $hostname
	$ip + "`t`t" + $hostname | Out-File -encoding ASCII -append $hostsFile
}

function Remove-HostsEntry([string]$hostname) {
	$hostsFile = "$env:windir\System32\drivers\etc\hosts"
	$c = Get-Content $hostsFile
	$newLines = @()
	foreach ($line in $c) {
		$bits = [regex]::Split($line, "\t+")
		if ($bits.count -eq 2) {
			if ($bits[1] -ne $hostname) {
				$newLines += $line
			}
		} else {
			$newLines += $line
		}
	}
	# Write file
	Clear-Content $hostsFile
	foreach ($line in $newLines) {
		$line | Out-File -encoding ASCII -append $hostsFile
	}
}

export-modulemember -function Add-HostsEntry, Remove-HostsEntry