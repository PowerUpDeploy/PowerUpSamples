include .\_powerup\deploy\combos\PsakeCombos\StandardSettingsAndRemoteExec.ps1

task deploy {
	run deploy-web ${web.servers}
}

task deploy-web  {
	import-module websitecombos

	$comboOptions = @{
		websitename = ${website.name};
		webroot = ${deployment.root};
		bindings = @(
					@{port = ${http.port};}
					@{port = ${https.port};protocol='https';}
					);
	}
				
	invoke-combo-standardwebsite($comboOptions)
}
