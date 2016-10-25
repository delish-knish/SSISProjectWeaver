CREATE PROCEDURE [ctl].[DeleteETLBatchExecution] @ETLBatchExecutionId INT
AS
    DELETE FROM log.[ETLBatchExecutionEvent]
    WHERE  [ETLBatchExecutionId] = @ETLBatchExecutionId

    DELETE FROM log.ETLPackageExecutionError
    WHERE  [ETLBatchExecutionId] = @ETLBatchExecutionId

	DELETE log.ETLPackageExecution 
	FROM log.ETLPackageExecution epe
		JOIN ctl.ETLBatchSSISDBExecutions ebs ON epe.SSISDBExecutionId = ebs.SSISDBExecutionId
    WHERE  ebs.[ETLBatchExecutionId] = @ETLBatchExecutionId

    DELETE FROM ctl.ETLBatchSSISDBExecutions
    WHERE  [ETLBatchExecutionId] = @ETLBatchExecutionId

    DELETE FROM ctl.[ETLBatchExecution]
    WHERE  [ETLBatchExecutionId] = @ETLBatchExecutionId

    RETURN 0 
