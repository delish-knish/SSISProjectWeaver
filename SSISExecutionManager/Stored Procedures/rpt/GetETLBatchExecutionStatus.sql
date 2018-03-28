CREATE PROCEDURE [rpt].[GetETLBatchExecutionStatus] @ETLBatchExecutionId INT
AS
    SELECT
      ETLBatchStatus
    FROM
      rpt.ETLBatchExecutions
    WHERE
      ETLBatchExecutionId = @ETLBatchExecutionId

    RETURN 0 
