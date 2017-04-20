CREATE FUNCTION [dbo].[func_IsETLBatchExecutionTimedOut] (@ETLBatchExecutionId INT)
RETURNS BIT
AS
  BEGIN
      DECLARE @Result      BIT = 0
              ,@ETLBatchId INT = (SELECT
                   ETLBatchId
                 FROM
                   ctl.ETLBatchExecution
                 WHERE
                  ETLBatchExecutionId = @ETLBatchExecutionId);
      DECLARE @BatchStartedWithinMinutes INT = ISNULL((SELECT
                  MinutesBackToContinueBatch
                FROM
                  ctl.ETLBatch
                WHERE
                 ETLBatchId = @ETLBatchId), 1440);

      IF EXISTS(SELECT
                  1
                FROM
                  ctl.ETLBatchExecution
                WHERE
                 DATEDIFF(MINUTE, StartDateTime, GETDATE()) <= @BatchStartedWithinMinutes
				 AND ETLBatchExecutionId = @ETLBatchExecutionId)
        BEGIN
            SET @Result = 0
        END
      ELSE
        SET @Result = 1

      RETURN @Result;

  END 
