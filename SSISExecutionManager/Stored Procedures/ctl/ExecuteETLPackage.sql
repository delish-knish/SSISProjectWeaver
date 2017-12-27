CREATE PROCEDURE [ctl].[ExecuteETLPackage] @ETLBatchExecutionId INT,
                                           @ETLPackageId        INT,
										   @ETLPackageGroupId	INT,
                                           @SSISEnvironmentName VARCHAR(128) = NULL,
                                           @SSISExecutionId     BIGINT = NULL OUT
AS
    DECLARE @SSISDBPackageName             NVARCHAR (260)
            ,@SSISDBProjectName            NVARCHAR(128)
            ,@SSISDBFolderName             NVARCHAR(128)
            ,@Use32BitDtExecInd            BIT
            ,@OverrideSSISDBLoggingLevelId INT
            ,@HasParamETLBatchExecutionId  BIT
            ,@EnvironmentReferenceId       INT = NULL

    --Get the package path values required by the create_execution stored procedure
    SELECT
      @SSISDBPackageName = ep.SSISDBPackageName
     ,@SSISDBProjectName = ep.SSISDBProjectName
     ,@SSISDBFolderName = ep.SSISDBFolderName
     ,@Use32BitDtExecInd = ep.Use32BitDtExecInd
     ,@EnvironmentReferenceId = env.reference_id
     ,@OverrideSSISDBLoggingLevelId = epgep.OverrideSSISDBLoggingLevelId
	 ,@HasParamETLBatchExecutionId = ep.HasParamETLBatchExecutionId
    FROM
      [cfg].ETLPackage ep
      JOIN [$(SSISDB)].[catalog].[packages] pkg
        ON ep.SSISDBPackageName = pkg.[name]
      JOIN [$(SSISDB)].[catalog].[projects] prj
        ON pkg.project_id = prj.project_id
           AND prj.[name] = ep.SSISDBProjectName
	  JOIN [cfg].ETLPackageGroup_ETLPackage epgep
		ON ep.ETLPackageId = epgep.ETLPackageId
			AND epgep.ETLPackageGroupId = @ETLPackageGroupId
      JOIN [$(SSISDB)].[catalog].[folders] fld
        ON prj.folder_id = fld.folder_id
           AND fld.[name] = ep.SSISDBFolderName
      LEFT JOIN (SELECT
                   project_id
                  ,reference_id
                 FROM
                   [$(SSISDB)].[catalog].[environment_references]
                 WHERE
                  environment_name = @SSISEnvironmentName) env
             ON prj.project_id = env.project_id
    WHERE
      ep.ETLPackageId = @ETLPackageId

    --Create the execution
    DECLARE @ExecutionId BIGINT

    EXEC [$(SSISDB)].[catalog].[create_execution]
      @package_name=@SSISDBPackageName --SSIS package name TABLE:(SELECT * FROM [SSISDB].internal.packages)
     ,@folder_name=@SSISDBFolderName --Folder were the package lives TABLE:(SELECT * FROM [SSISDB].internal.folders)
     ,@project_name=@SSISDBProjectName --Project name were SSIS package lives TABLE:(SELECT * FROM [SSISDB].internal.projects)
     ,@use32bitruntime=@Use32BitDtExecInd --Use the 32 dtexec runtime
     ,@reference_id=@EnvironmentReferenceId --Environment reference, if null then no environment configuration is applied.
     ,@execution_id=@ExecutionId OUTPUT --The paramter is outputed and contains the execution_id of your SSIS execution context.

    IF @HasParamETLBatchExecutionId = 1
      BEGIN
          DECLARE @ETLBatchExecutionIdParam SQL_VARIANT = @ETLBatchExecutionId --Parameter value needs to a sql_variant

          EXEC [$(SSISDB)].[catalog].[set_execution_parameter_value]
            @ExecutionId           -- The execution_id value we received by calling [create_execution]
           ,@object_type=30           --30 is Package Parameters, you can also use 20 for Project parameters or 50 for Environment
           ,@parameter_name=N'ETLBatchExecutionId'           --Parameter name
            ,@parameter_value= @ETLBatchExecutionIdParam
      END

    --Set the logging level if an override is configured
    IF @OverrideSSISDBLoggingLevelId IS NOT NULL
      BEGIN
          EXEC [$(SSISDB)].[catalog].[set_execution_parameter_value]
            @ExecutionId           -- The execution_id value we received by calling [create_execution]
            ,@object_type=50           --30 is Package Parameters, you can also use 20 for Project parameters or 50 for Environment
            ,@parameter_name=N'LOGGING_LEVEL'           --Parameter name
            ,@parameter_value= @OverrideSSISDBLoggingLevelId
      END

    --Execute the package
    EXEC [$(SSISDB)].[catalog].[start_execution]
      @ExecutionId

    --Set the ReadyForExecutionInd on the package so that it is not picked up
    UPDATE [cfg].ETLPackageGroup_ETLPackage
    SET    ReadyForExecutionInd = 0
    WHERE
      ETLPackageId = @ETLPackageId
	  AND ETLPackageGroupId = @ETLPackageGroupId

    --Associate the SSISDB Execution ID with the batch 
    EXEC ctl.InsertETLBatchSSISDBExecution
      @ETLBatchExecutionId
     ,@ExecutionId
     ,@ETLPackageId
	 ,@ETLPackageGroupId

    --Set the ouput parameter so that we can then look up the execution in the SSISDB
    SET @SSISExecutionId = @ExecutionId

    RETURN 0 
