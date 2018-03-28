CREATE FUNCTION [dbo].[func_GetETLBatchStatusId] (@ETLBatchExecutionId INT)
RETURNS INT
AS
  BEGIN
      DECLARE @ReturnValue INT = (SELECT
           ETLBatchStatusId
         FROM
           ctl.[ETLBatchExecution]
         WHERE
          [ETLBatchExecutionId] = @ETLBatchExecutionId)

      RETURN @ReturnValue
  END 
