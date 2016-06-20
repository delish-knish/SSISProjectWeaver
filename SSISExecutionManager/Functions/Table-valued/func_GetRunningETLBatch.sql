CREATE FUNCTION [dbo].[func_GetRunningETLBatch] (@BatchStartedWithinMinutes SMALLINT,
                                                 @SQLAgentJobName           VARCHAR(128))
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
         ctl.[ETLBatchExecution]
       WHERE
        DATEDIFF(MINUTE, StartDateTime, GETDATE()) <= @BatchStartedWithinMinutes
        AND EndDateTime IS NULL
        AND SQLAgentJobName = @SQLAgentJobName) 
