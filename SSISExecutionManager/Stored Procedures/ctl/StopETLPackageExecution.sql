CREATE PROCEDURE [ctl].[StopETLPackageExecution] @SSISDBExecutionId BIGINT
AS
    DECLARE @ETLBatchExecutionId INT
            ,@SSISDBProjectName  NVARCHAR (128)
            ,@ETLPackageId       INT
            ,@SSISDBPackageName  NVARCHAR(260)
            ,@EventDescription   VARCHAR(MAX);

    SELECT
      @ETLBatchExecutionId = exm.ETLBatchExecutionId
      ,@SSISDBProjectName = project_name
      ,@SSISDBPackageName = package_name
      ,@ETLPackageId = exm.ETLPackageId
    FROM
      [$(SSISDB)].[catalog].executions ex
      JOIN ctl.ETLBatchSSISDBExecutions exm
        ON ex.execution_id = exm.SSISDBExecutionId
    WHERE
      [status] = 2
      AND exm.SSISDBExecutionId = @SSISDBExecutionId

    DECLARE @SQLStopPackageExecution NVARCHAR(MAX) = 'EXEC SSISDB.catalog.stop_operation @operation_id = '
      + CAST(@SSISDBExecutionId AS NVARCHAR(20));

    EXECUTE master.sys.sp_executesql
      @SQLStopPackageExecution

    SET @EventDescription = 'Stopping SSISDB package execution Id '
                            + CAST(@SSISDBExecutionId AS VARCHAR(20))
                            + '[' + @SSISDBProjectName + '].['
                            + @SSISDBPackageName + ']';

    EXEC [log].[InsertETLBatchExecutionEvent]
      21,
      @ETLBatchExecutionId,
      @ETLPackageId,
      @EventDescription;

    RETURN 0 
