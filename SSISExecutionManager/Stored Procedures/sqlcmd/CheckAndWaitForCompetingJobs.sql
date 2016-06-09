CREATE PROCEDURE [sqlcmd].[CheckAndWaitForCompetingJobs] @SQLAgentJobName          VARCHAR(128),
                                                         --@Periodicity              CHAR(2),
                                                         @HourlyInd                BIT,
                                                         @SQLAgentJobNameToWaitFor VARCHAR(128),
                                                         @ETLBatchId               INT,
														 @EndETLBatchExecutionInd BIT OUT
AS
    DECLARE @EventDescription          VARCHAR(MAX),
            @PollingDelayMinutes       INT = ( [dbo].[func_GetConfigurationValue] ('Polling Delay in Minutes') ),
            @BatchStartedWithinMinutes INT = ( [dbo].[func_GetConfigurationValue] ('Minutes Back to Continue a Batch') ),
            @HourlyJobTimeoutInMinutes SMALLINT = ( [dbo].[func_GetConfigurationValue] ('Hourly Job Timeout In Minutes') ),
            @ErrorEmailRecipients      VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Email Recipients - Default') ),
            @SendTimeoutNotification   BIT = ( [dbo].[func_GetConfigurationValue] ('Send Timeout Notifications') ),
            @BatchDayOfWeekName        VARCHAR(10),
            @BatchStartDateTime        DATETIME2,
            @ETLBatchTimeOutStatusId   INT = 8,
            @TimeoutEmailSubject       VARCHAR(MAX) = @@SERVERNAME + ' ' + @SQLAgentJobName + ' Timed Out';

    --Format Delay Length for WAITFOR function
    DECLARE @DelayLength CHAR(8)= '00:0' + CAST(@PollingDelayMinutes AS VARCHAR(3)) + ':00';

    --Get running ETLBatch
    SELECT
      @BatchDayOfWeekName = DayOfWeekName
      ,@BatchStartDateTime = StartDateTime
    FROM
      [dbo].[func_GetRunningETLBatch] (@BatchStartedWithinMinutes, @SQLAgentJobName) eb

    WHILE [dbo].[func_IsSQLAgentJobRunning](@SQLAgentJobNameToWaitFor) = 1
      BEGIN
          SET @EventDescription = 'Waiting for [' + @SQLAgentJobNameToWaitFor + '] job to complete. Wait interval ' + @DelayLength;

          EXEC [log].InsertETLBatchEvent 10,@ETLBatchId,NULL,@EventDescription;

          WAITFOR DELAY @DelayLength

          --Check timeout condition for hourly job (we don't want to timeout daily job) 
          IF ( DATEDIFF(MINUTE, @BatchStartDateTime, GETDATE()) > @HourlyJobTimeoutInMinutes
               AND @HourlyInd = 1 )
            BEGIN
                SET @EventDescription = 'The ' + @SQLAgentJobName + ' job timed out after ' + CAST(@HourlyJobTimeoutInMinutes AS VARCHAR(5)) + ' minutes while waiting for the ' + @SQLAgentJobNameToWaitFor + ' job to complete.';

                EXEC [log].InsertETLBatchEvent 14,@ETLBatchId,NULL,@EventDescription;

                --Mark the batch as 'Timed Out', set the EndDateTime so that the batch is not picked up for execution again, and send notification if configured to do so
                EXEC [ctl].[EndETLBatch] @ETLBatchId = @ETLBatchId,@ETLBatchStatusId = @ETLBatchTimeOutStatusId

                EXEC msdb.dbo.sp_send_dbmail @recipients = @ErrorEmailRecipients,@subject = @TimeoutEmailSubject,@body = @EventDescription,@importance = 'Normal';

				SET @EndETLBatchExecutionInd = 1;

				RETURN;
            END
      END

	  SET @EndETLBatchExecutionInd = 0;

    RETURN 0 
