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
		 ,eb.SendBatchCompleteEmailInd
       FROM
         ctl.[ETLBatchExecution] ebe (NOLOCK)
		 JOIN ctl.[ETLBatch] eb (NOLOCK)
			ON ebe.ETLBatchId = eb.ETLBatchId
       WHERE
        DATEDIFF(MINUTE, StartDateTime, GETDATE()) <= @BatchStartedWithinMinutes
        AND EndDateTime IS NULL
        AND CallingJobName = @CallingJobName
		AND ETLBatchStatusId <> 1) --To handle batches that have been created but are waiting on SQL Command Conditions - might have to revisit 
