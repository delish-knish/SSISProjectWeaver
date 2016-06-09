CREATE PROCEDURE [ctl].[DeleteETLBatch] @ETLBatchId INT
AS
    DELETE FROM log.ETLBatchEvent
    WHERE  ETLBatchId = @ETLBatchId

    DELETE FROM log.ETLPackageExecutionError
    WHERE  ETLBatchId = @ETLBatchId

    DELETE FROM ctl.ETLBatchSSISDBExecutions
    WHERE  ETLBatchId = @ETLBatchId

    DELETE FROM ctl.ETLBatch
    WHERE  ETLBatchId = @ETLBatchId

    RETURN 0 
