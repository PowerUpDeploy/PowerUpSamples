#SimpleWebsite

## How to run

This sample shows a very simple example of a Asp.Net MVC website being built and deployed locally.

To use, execute the following on the command line

  build
  cd _package
  deploy local
  
This uses nant to build the solution, then powershell to deploy a new website available at http://localhost:9000 and https://localhost:9001

### main.build

Contains configuration for setting the solution file name, and detailed what to place in the build package

### deploy.ps1

Powershell script of what and how to deploy. For more information of what is possible, explore the modules directory in _powerup/deploy/modules

### settings.txt

Configuration that becomes variables in the above script, but also available for templated config files

### _templates

Templated config files, where settings are textual substituted

### servers.txt 

Configuration for the servers to deploy to (if remote deployments are used)

### build.bat and bootstrap.bat

Convenience batch files to ease builds

## How to adapt to your own solution

- Add PowerUp as a nuget package in your solution
- Copy build.bat and bootstrap.bat to your solution root
- Copy main.build, deploy.ps1, servers.txt, settings.txt and _templates to your solution. These will need to be edited to suit your solution
- Add any new settings you require for deploy.ps1 & files in _templates to settings.txt
- Alter main.build to run test, build additional solutions and change the patterns for what files to place in your package
- Alter deploy.ps1 to deploy additional websites, queues, windows service etc. Look at _powerup/deploy/modules and _powerup/deploy/combos for what is available





