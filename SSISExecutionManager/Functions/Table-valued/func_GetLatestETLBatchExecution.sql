CREATE FUNCTION [dbo].[func_GetLatestETLBatchExecution] (@ETLBatchId INT)
RETURNS TABLE
AS
    RETURN
      (SELECT
         [ETLBatchExecutionId]
       FROM
         (SELECT
            [ETLBatchExecutionId]
            ,ROW_NUMBER()
               OVER (
                 PARTITION BY [ETLBatchId]
                 ORDER BY StartDateTime DESC) rownum
          FROM
            [ctl].[ETLBatchExecution] WITH (NOLOCK)
          WHERE
           [ETLBatchId] = @ETLBatchId) t
       WHERE
        t.rownum = 1) 
