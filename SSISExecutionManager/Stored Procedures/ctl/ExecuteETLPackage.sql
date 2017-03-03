CREATE PROCEDURE [ctl].[ExecuteETLPackage] @ETLBatchId          INT,
                                           @ETLPackageId        INT,
                                           @SSISEnvironmentName VARCHAR(128) = NULL,
                                           @SSISExecutionId     BIGINT = NULL OUT
AS
    DECLARE @SSISDBPackageName             NVARCHAR (260),
            @SSISDBProjectName             NVARCHAR(128),
            @SSISDBFolderName              NVARCHAR(128),
            @Use32BitDtExecInd             BIT,
			@SSISDBLoggingLevelId		INT,
            @EnvironmentReferenceId        INT = NULL

    --Get the package path values required by the create_execution stored procedure
    SELECT
      @SSISDBPackageName = ep.SSISDBPackageName
      ,@SSISDBProjectName = ep.SSISDBProjectName
      ,@SSISDBFolderName = ep.SSISDBFolderName
      ,@Use32BitDtExecInd = ep.Use32BitDtExecInd
      ,@EnvironmentReferenceId = env.reference_id
	  ,@SSISDBLoggingLevelId = ISNULL(ep.SSISDBLoggingLevelId, 1)
    FROM
      [ctl].ETLPackage ep
      JOIN [$(SSISDB)].[catalog].[packages] pkg
        ON ep.SSISDBPackageName = pkg.name
      JOIN [$(SSISDB)].[catalog].[projects] prj
        ON pkg.project_id = prj.project_id
           AND prj.name = ep.SSISDBProjectName
      JOIN [$(SSISDB)].[catalog].[folders] fld
        ON prj.folder_id = fld.folder_id
           AND fld.name = ep.SSISDBFolderName
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

    EXEC [$(SSISDB)].[catalog].[create_execution] @package_name=@SSISDBPackageName,--SSIS package name TABLE:(SELECT * FROM [SSISDB].internal.packages)
                                                  @folder_name=@SSISDBFolderName,--Folder were the package lives TABLE:(SELECT * FROM [SSISDB].internal.folders)
                                                  @project_name=@SSISDBProjectName,--Project name were SSIS package lives TABLE:(SELECT * FROM [SSISDB].internal.projects)
                                                  @use32bitruntime=@Use32BitDtExecInd,--Use the 32 dtexec runtime
                                                  @reference_id=@EnvironmentReferenceId,--Environment reference, if null then no environment configuration is applied.
                                                  @execution_id=@ExecutionId OUTPUT --The paramter is outputed and contains the execution_id of your SSIS execution context.

    /*--Set parameter values
    Use this logic to set generic parameters that can be found in entry-point packages. An example would be if some packages have a daily/hourly
		parameter and they behave differently based on this parameter. You could store a flag such as "ContainsPeriodicityIntelligenceInd" in the ETLPackage table
		and if the bit = 1 then the execute method will expect that this parameter will be passed (likely originating from the ctl.ExecuteETLBatch stored procedure
	
	IF @ContainsPeriodicityIntelligence = 1 --We need to pass the param to a package parameter
      BEGIN
          DECLARE @PeriodicityParam SQL_VARIANT = @PeriodicityParam --Parameter value needs to a sql_variant

          EXEC [$(SSISDB)].[catalog].[set_execution_parameter_value] @ExecutionId,-- The execution_id value we received by calling [create_execution]
                                                                     @object_type=30,--30 is Package Parameters, you can also use 20 for Project parameters or 50 for Environment
                                                                     @parameter_name=N'Periodicity',--Parameter name
                                                                     @parameter_value= @PeriodicityParam
      END */


    --Set the logging level
	EXEC [$(SSISDB)].[catalog].[set_execution_parameter_value] @ExecutionId,-- The execution_id value we received by calling [create_execution]
                                                                     @object_type=50,--30 is Package Parameters, you can also use 20 for Project parameters or 50 for Environment
                                                                     @parameter_name=N'LOGGING_LEVEL',--Parameter name
                                                                     @parameter_value= @SSISDBLoggingLevelId

    --Execute the package
    EXEC [$(SSISDB)].[catalog].[start_execution] @ExecutionId

    --Set the ReadyForExecutionInd on the package so that it is not picked up
    UPDATE [ctl].ETLPackage
    SET    ReadyForExecutionInd = 0
    WHERE
      ETLPackageId = @ETLPackageId

    --Associate the SSISDB Execution ID with the batch 
    EXEC ctl.InsertETLBatchSSISDBExecution @ETLBatchId,@ExecutionId,@ETLPackageId

    --Set the ouput parameter so that we can then look up the execution in the SSISDB
    SET @SSISExecutionId = @ExecutionId

    RETURN 0 
