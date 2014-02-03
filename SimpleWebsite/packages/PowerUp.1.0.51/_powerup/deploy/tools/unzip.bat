@echo off

:RUN
	call _powerup\deploy\core\ensure_prerequisites.bat
	powershell -inputformat none .\_powerup\deploy\tools\unzip.ps1 
	