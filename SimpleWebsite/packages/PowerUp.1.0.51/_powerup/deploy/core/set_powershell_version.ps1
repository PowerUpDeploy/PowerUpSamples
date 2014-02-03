if ($psversiontable.clrversion.major -lt 4)
{
	$currentPath = Get-Location
	Copy-Item $currentPath\_powerup\deploy\core\powershell.exe.config -destination $pshome -force 	
}
