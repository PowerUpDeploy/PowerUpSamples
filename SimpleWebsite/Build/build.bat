@echo off
if "%~1"=="/?" (
    GOTO :print-usage
) else (
    GOTO :main
)

:print-usage
echo(
echo build.bat Usage
echo(
echo build.bat                                                ^| Full build and test run
echo build.bat [nant task name]                               ^| Run specific nant task
GOTO :end


:main
call nuget-restore.bat
pushd bootstrapper
call bootstrap.bat powerup
popd

echo calling nant with args %*
_powerup\build\nant\nant-40\bin\nant -buildfile:main.build %*

:end
EXIT /B %errorlevel%