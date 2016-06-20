--Parameters
DECLARE @SSISDBFolderName NVARCHAR(128) = 'SSISExecutionManager_Example1';
DECLARE @SSISServerName NVARCHAR(128) = '$(SSISServerName)'
DECLARE @SSIDBFolderId BIGINT;
DECLARE @SSISDBEnvironmentId BIGINT;

--Create top-level folder
EXEC SSISDB.catalog.create_folder @SSISDBFolderName,@SSIDBFolderId OUTPUT;

/*Deploy the projects */
DECLARE @Command VARCHAR(8000) = 'cd.. && "$(SolutionRootDir)SSISExecutionManager\Scripts\Example 1 Setup\Deploy Example1 SSIS Projects.bat" "' + @SSISServerName + '" "$(SolutionRootDir)"' 
EXEC master.sys.xp_cmdshell @Command;

--Set the connection managers
DECLARE @var sql_variant = N'$(SSISServerName)'
EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type=20, @parameter_name=N'CM.localhost.master.ServerName', @object_name=N'ExampleProjectA', @folder_name=N'SSISExecutionManager_Example1', @project_name=N'ExampleProjectA', @value_type=V, @parameter_value=@var
EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type=20, @parameter_name=N'CM.localhost.master.ServerName', @object_name=N'ExampleProjectB', @folder_name=N'SSISExecutionManager_Example1', @project_name=N'ExampleProjectB', @value_type=V, @parameter_value=@var
