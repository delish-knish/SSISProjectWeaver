CREATE FUNCTION [dbo].[func_GetLatestETLBatch] (@ETLPackageSetId INT)
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
            [ctl].[ETLBatchExecution]
          WHERE
           [ETLBatchId] = @ETLPackageSetId) t
       WHERE
        t.rownum = 1) 
