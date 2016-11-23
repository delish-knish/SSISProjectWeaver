CREATE FUNCTION [dbo].[func_GetRunningETLBatchExecution] (@BatchStartedWithinMinutes SMALLINT,
															@CallingJobName           VARCHAR(128))
RETURNS TABLE
AS
    RETURN
      (SELECT
         ETLBatchExecutionId
         ,ETLBatchStatusId
         ,DayOfWeekName
         ,StartDateTime
		 ,ETLBatchId
		 ,ETLBatchPhaseId
       FROM
         ctl.[ETLBatchExecution] WITH (NOLOCK)
       WHERE
        DATEDIFF(MINUTE, StartDateTime, GETDATE()) <= @BatchStartedWithinMinutes
        AND EndDateTime IS NULL
        AND CallingJobName = @CallingJobName) 
