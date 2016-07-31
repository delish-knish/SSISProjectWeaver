CREATE PROCEDURE [sqlcmd].[CheckAndWaitForCompetingJobs] @CallingJobName          VARCHAR(128),
                                                         @CallingJobNameToWaitFor VARCHAR(128),
                                                         @ETLBatchId               INT,
														 @EndETLBatchExecutionInd BIT OUT
AS
    DECLARE @EventDescription          VARCHAR(MAX),
            @PollingDelay			   CHAR(8) = ( [dbo].[func_GetConfigurationValue] ('Default SQL Command Trigger Polling Delay') ),
            @BatchStartedWithinMinutes INT = ( [dbo].[func_GetConfigurationValue] ('Minutes Back to Continue a Batch') ),
            @ErrorEmailRecipients      VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Email Recipients - Default') ),
            @SendTimeoutNotification   BIT = ( [dbo].[func_GetConfigurationValue] ('Send Timeout Notifications') ),
            @BatchDayOfWeekName        VARCHAR(10),
            @BatchStartDateTime        DATETIME2,
            @ETLBatchTimeOutStatusId   INT = 8,
            @TimeoutEmailSubject       VARCHAR(MAX) = @@SERVERNAME + ' ' + @CallingJobName + ' Timed Out';

    --Get running ETLBatch
    SELECT
      @BatchDayOfWeekName = DayOfWeekName
      ,@BatchStartDateTime = StartDateTime
    FROM
      [dbo].[func_GetRunningETLBatchExecution] (@BatchStartedWithinMinutes, @CallingJobName) eb

    WHILE [dbo].[func_IsSQLAgentJobRunning](@CallingJobNameToWaitFor) = 1
      BEGIN
          SET @EventDescription = 'Waiting for [' + @CallingJobNameToWaitFor + '] job to complete. Wait interval ' + @PollingDelay;

          EXEC [log].InsertETLBatchEvent 10,@ETLBatchId,NULL,@EventDescription;

          WAITFOR DELAY @PollingDelay;
      END

	  SET @EndETLBatchExecutionInd = 0;

    RETURN 0 