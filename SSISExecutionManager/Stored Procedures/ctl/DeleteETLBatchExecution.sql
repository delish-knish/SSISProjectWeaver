CREATE PROCEDURE [ctl].[DeleteETLBatchExecution] @ETLBatchExecutionId INT
AS
    DELETE FROM log.[ETLBatchExecutionEvent]
    WHERE  [ETLBatchExecutionId] = @ETLBatchExecutionId

    DELETE FROM log.ETLPackageExecutionError
    WHERE  [ETLBatchExecutionId] = @ETLBatchExecutionId

    DELETE FROM ctl.ETLBatchSSISDBExecutions
    WHERE  [ETLBatchExecutionId] = @ETLBatchExecutionId

    DELETE FROM ctl.[ETLBatchExecution]
    WHERE  [ETLBatchExecutionId] = @ETLBatchExecutionId

    RETURN 0 
