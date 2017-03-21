CREATE FUNCTION [dbo].[func_GetRunningETLBatchExecution] (@BatchStartedWithinMinutes SMALLINT,
															@CallingJobName           VARCHAR(128))
RETURNS TABLE
AS
    RETURN
      (SELECT
          ebe.ETLBatchExecutionId
         ,ebe.ETLBatchStatusId
         ,ebe.DayOfWeekName
         ,ebe.StartDateTime
		 ,ebe.ETLBatchId
		 ,eb.MinutesBackToContinueBatch
		 ,eb.SendBatchCompleteEmailInd
       FROM
         ctl.[ETLBatchExecution] ebe (NOLOCK)
		 JOIN ctl.[ETLBatch] eb (NOLOCK)
			ON ebe.ETLBatchId = eb.ETLBatchId
       WHERE
        DATEDIFF(MINUTE, StartDateTime, GETDATE()) <= @BatchStartedWithinMinutes
        AND EndDateTime IS NULL
        AND CallingJobName = @CallingJobName) 
