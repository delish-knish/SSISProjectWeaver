CREATE PROCEDURE [sqlcmd].[StartDelayedSQLAgentJob] @SQLAgentJobName VARCHAR(128)
AS
	 --Get values from Config table
    DECLARE @MaxDelay INT = ( [dbo].[func_GetConfigurationValue] ('Max Delay Between Daily Jobs For Auto Start In Minutes') );

    --If execution of current job completed past the scheduled start time of the "other" job but within 2 hours of the scheduled start time, start the other job
    DECLARE @NextRunTime DATETIME2 = (SELECT
         [dbo].[func_GetSQLAgentJobNextRunDateTime] (@SQLAgentJobName))

    IF @NextRunTime < GETDATE()
       AND DATEDIFF(minute, @NextRunTime, GETDATE()) <= @MaxDelay
      BEGIN
          EXEC msdb.dbo.sp_start_job @SQLAgentJobName;
      END

    RETURN 0 
