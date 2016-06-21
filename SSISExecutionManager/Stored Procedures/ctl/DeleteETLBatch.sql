CREATE PROCEDURE [ctl].[DeleteETLBatch] @ETLBatchId INT
AS
    DELETE FROM log.[ETLBatchExecutionEvent]
    WHERE  [ETLBatchExecutionId] = @ETLBatchId

    DELETE FROM log.ETLPackageExecutionError
    WHERE  ETLBatchId = @ETLBatchId

    DELETE FROM ctl.ETLBatchSSISDBExecutions
    WHERE  [ETLBatchExecutionId] = @ETLBatchId

    DELETE FROM ctl.[ETLBatchExecution]
    WHERE  [ETLBatchExecutionId] = @ETLBatchId

    RETURN 0 
