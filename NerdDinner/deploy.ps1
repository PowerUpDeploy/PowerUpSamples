include .\_powerup\deploy\combos\PsakeCombos\StandardSettingsAndRemoteExec.ps1

task deploy {
	run deploywebsite ${web.servers}
}

task deploywebsite  {
	import-module websitecombos
	import-module powerupfilesystem

	$comboOptions = @{
		websitename = ${website.name};
		webroot = ${web.root};
		sourcefolder = 'NerdDinnerWebsite'
		bindings = @(
					@{port = ${http.port};}
					);
	}
				
	invoke-combo-standardwebsite($comboOptions)
	
	if (!(Test-Path ${database.directory}))
	{
		copy-mirroreddirectory $(get-location)\NerdDinnerDatabases ${database.directory} 
	}
}
