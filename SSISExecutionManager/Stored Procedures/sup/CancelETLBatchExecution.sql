CREATE PROCEDURE [sup].[CancelETLBatchExecution] @ETLBatchExecutionId INT
AS
    EXEC [ctl].[EndETLBatchExecution]
      @ETLBatchExecutionId,
      10;

    EXEC ctl.StopAllPackagesForETLBatchExecution
      @ETLBatchExecutionId;

    EXEC [log].[InsertETLBatchExecutionEvent]
      6,
      @ETLBatchExecutionId,
      NULL,
      'Batch canceled';

    RETURN 0 
