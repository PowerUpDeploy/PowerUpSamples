param (
	[string]$source = $(throw "Package source is required"),
	[string]$packageId = $(throw "Package Id is required")
)

& .\nuget.exe update -Self
& .\nuget.exe install -Source $source -NoCache -NonInteractive -OutputDirectory ..\packages $packageId