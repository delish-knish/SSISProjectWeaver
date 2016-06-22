@echo off
set ssisServer=%1
set DeploymentPackagePath=%~2

echo.
echo Deploying SSIS project "ExampleProjectA"...

set ispacName=ExampleProjectA.ispac
set ispacPath=%DeploymentPackagePath%\ExampleProjectA\bin\Release\%ispacName%

REM echo %DeploymentPackagePath%
REM echo %ispacPath%

ISDeploymentWizard.exe /Silent /SourcePath:"%ispacPath%" /DestinationServer:%ssisServer% /DestinationPath:"/SSISDB/SSISExecutionManager_Example1/ExampleProjectA"

echo Deployment of "ExampleProjectA" project complete.
echo.

echo Deploying SSIS project "ExampleProjectB"...

set ispacName=ExampleProjectB.ispac
set ispacPath=%DeploymentPackagePath%\ExampleProjectB\bin\Release\%ispacName%

REM echo %DeploymentPackagePath%
REM echo %ispacPath%

ISDeploymentWizard.exe /Silent /SourcePath:"%ispacPath%" /DestinationServer:%ssisServer% /DestinationPath:"/SSISDB/SSISExecutionManager_Example1/ExampleProjectB"

echo Deployment of "ExampleProjectB" project complete.
echo.