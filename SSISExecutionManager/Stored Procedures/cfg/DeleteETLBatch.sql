CREATE PROCEDURE [cfg].[DeleteETLBatch] @ETLBatchId      INT = NULL
AS
    SELECT
      @ETLBatchId = ETLBatchId
    FROM
      [cfg].ETLBatch
    WHERE
      ETLBatchId = @ETLBatchId;

    IF @ETLBatchId IS NULL
      THROW 50012, 'The ETL Batch does not exist.', 1;
    ELSE
      BEGIN
          DELETE sebe 
		  FROM [ctl].[ETLBatchSSISDBExecutions] sebe
			JOIN ctl.ETLBatchExecution ebe ON sebe.ETLBatchExecutionId = ebe.ETLBatchExecutionId 
          WHERE  ebe.ETLBatchId = @ETLBatchId;

          DELETE ebee
		  FROM [log].[ETLBatchExecutionEvent] ebee
			JOIN ctl.ETLBatchExecution ebe ON ebee.ETLBatchExecutionId = ebe.ETLBatchExecutionId
          WHERE  ebe.ETLBatchId = @ETLBatchId;

          DELETE FROM ctl.ETLBatchExecution
          WHERE  ETLBatchId = @ETLBatchId;

          DELETE FROM [cfg].[ETLBatch_ETLPackageGroup]
          WHERE  ETLBatchId = @ETLBatchId;

          DELETE FROM [cfg].ETLBatch
          WHERE  ETLBatchId = @ETLBatchId;
      END

    RETURN 0 
