include .\_powerup\deploy\combos\PsakeCombos\StandardSettingsAndRemoteExec.ps1

task deploy {
	run web-deploy-combo ${web.servers}
}

task web-deploy-combo  {
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

task web-deploy-moves  {
	import-module powerupfilesystem
	import-module powerupweb

	$packageFolder = get-location
	copy-mirroreddirectory $packageFolder\simplewebsite ${deployment.root}\${website.name} 

	set-webapppool ${website.name} "Integrated" "v4.0"
	set-website ${website.name} ${website.name} ${deployment.root}\${website.name} "" "http" "*" ${http.port} 	
}