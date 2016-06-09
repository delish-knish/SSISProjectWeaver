CREATE FUNCTION [dbo].[func_GetRunningETLBatch] (@BatchStartedWithinMinutes SMALLINT,
                                                 @SQLAgentJobName           VARCHAR(128))
RETURNS TABLE
AS
    RETURN
      (SELECT
         ETLBatchId
         ,ETLBatchStatusId
         ,DayOfWeekName
         ,StartDateTime
		 ,ETLPackageSetId
       FROM
         ctl.ETLBatch
       WHERE
        DATEDIFF(MINUTE, StartDateTime, GETDATE()) <= @BatchStartedWithinMinutes
        AND EndDateTime IS NULL
        AND SQLAgentJobName = @SQLAgentJobName) 
