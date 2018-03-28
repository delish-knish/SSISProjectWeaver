CREATE PROCEDURE [ctl].[StopAllPackagesForETLBatchExecution] @ETLBatchExecutionId INT
AS
    DECLARE @SSISDBExecutionId BIGINT
    DECLARE PackageCursor CURSOR FAST_FORWARD FOR
      SELECT
        execution_id AS SSISDBExecutionId
      FROM
        [$(SSISDB)].[catalog].executions ex
        JOIN ctl.ETLBatchSSISDBExecutions exm
          ON ex.execution_id = exm.SSISDBExecutionId
      WHERE
        [status] = 2
        AND exm.ETLBatchExecutionId = @ETLBatchExecutionId

    OPEN PackageCursor

    FETCH NEXT FROM PackageCursor INTO @SSISDBExecutionId

    WHILE @@FETCH_STATUS = 0
      BEGIN
          EXEC [ctl].[StopETLPackageExecution]
            @SSISDBExecutionId = @SSISDBExecutionId;

          FETCH NEXT FROM PackageCursor INTO @SSISDBExecutionId
      END

    CLOSE PackageCursor

    DEALLOCATE PackageCursor

    RETURN 0 
