@echo off
if '%1'=='' goto NOSOURCEORPACKAGE
if '%2'=='' goto NOSOURCEORPACKAGE
goto RUN

:NOSOURCEORPACKAGE
	echo Package source name and package Id are required
	echo e.g. UpdatePackage.bat WynyardServer PowerUp
	exit /B
	
:RUN
	powershell -ExecutionPolicy Bypass -inputformat none -command ".\updatepackage.ps1 -source %1 -packageId %2"

	if %ERRORLEVEL% EQU 0 goto OK  
	if %ERRORLEVEL% GEQ 1 goto ERROR

:OK
	exit /B

:ERROR
	echo Check nuget.exe is in your path	
	exit /B