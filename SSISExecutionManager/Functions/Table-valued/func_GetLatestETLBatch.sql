CREATE FUNCTION [dbo].[func_GetLatestETLBatch] (@ETLPackageSetId INT)
RETURNS TABLE
AS
    RETURN
      (SELECT
         ETLBatchId
       FROM
         (SELECT
            ETLBatchId
            ,ROW_NUMBER()
               OVER (
                 PARTITION BY ETLPackageSetId
                 ORDER BY StartDateTime DESC) rownum
          FROM
            [ctl].ETLBatch
          WHERE
           ETLPackageSetId = @ETLPackageSetId) t
       WHERE
        t.rownum = 1) 
