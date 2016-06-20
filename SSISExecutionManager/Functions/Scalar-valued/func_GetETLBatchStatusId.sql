CREATE FUNCTION [dbo].[func_GetETLBatchStatusId] (@ETLBatchId INT)
RETURNS INT
AS
  BEGIN
      DECLARE @ReturnValue INT = (SELECT
           ETLBatchStatusId
         FROM
           ctl.[ETLBatchExecution]
         WHERE
          [ETLBatchExecutionId] = @ETLBatchId)

      RETURN @ReturnValue
  END 
