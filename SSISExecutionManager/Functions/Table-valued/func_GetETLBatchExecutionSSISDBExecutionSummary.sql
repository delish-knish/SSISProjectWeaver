CREATE FUNCTION [dbo].[func_GetETLBatchExecutionSSISDBExecutionSummary] (@ETLBatchExecutionId INT)
RETURNS TABLE
AS
    RETURN
      (SELECT
         bx.[ETLBatchExecutionId]
        ,COUNT(*)                     AS TotalExecutionCount
        ,SUM(IIF(x.status = 1, 1, 0)) AS CreatedCount
        ,SUM(IIF(x.status = 2, 1, 0)) AS RunningCount
        ,SUM(IIF(x.status = 3, 1, 0)) AS CanceledCount
        ,SUM(IIF(x.status = 4, 1, 0)) AS FailedCount
        ,SUM(IIF(x.status = 5, 1, 0)) AS PendingCount
        ,SUM(IIF(x.status = 6, 1, 0)) AS EndedUnexpectedlyCount
        ,SUM(IIF(x.status = 7, 1, 0)) AS SucceededCount
        ,SUM(IIF(x.status = 8, 1, 0)) AS StoppingCount
        ,SUM(IIF(x.status = 8, 1, 0)) AS CompletedCount
       FROM
         [ctl].[ETLBatchSSISDBExecutions] bx
         LEFT JOIN [$(SSISDB)].[catalog].[executions] x
                ON bx.SSISDBExecutionId = x.execution_id
	   WHERE
		bx.[ETLBatchExecutionId] = @ETLBatchExecutionId
       GROUP  BY
        bx.[ETLBatchExecutionId]) 
