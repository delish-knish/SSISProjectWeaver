CREATE FUNCTION [dbo].[func_GetETLBatchStatusId] (@ETLBatchId INT)
RETURNS INT
AS
  BEGIN
      DECLARE @ReturnValue INT = (SELECT
           ETLBatchStatusId
         FROM
           ctl.ETLBatch
         WHERE
          ETLBatchId = @ETLBatchId)

      RETURN @ReturnValue
  END 
