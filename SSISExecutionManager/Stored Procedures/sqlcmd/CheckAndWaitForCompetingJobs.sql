CREATE PROCEDURE [sqlcmd].[CheckAndWaitForCompetingJobs] @ETLBatchId              INT,
                                                         @CallingJobName          VARCHAR(128) = NULL,
                                                         @JobNameToWaitFor        VARCHAR(128),
                                                         @EndETLBatchExecutionInd BIT OUT,
														 @PollingDelayOverride CHAR(8) = NULL
AS
    DECLARE @EventDescription           VARCHAR(MAX)
            ,@PollingDelay              CHAR(8) = (ISNULL(@PollingDelayOverride, ([dbo].[func_GetConfigurationValue] ('Default SQL Command Condition Evaluation Polling Delay'))))
            ,@BatchStartedWithinMinutes INT = (TRY_CAST(ISNULL((SELECT  MinutesBackToContinueBatch FROM [cfg].ETLBatch WHERE ETLBatchId = @ETLBatchId), 1440) AS INT))
            ,@ETLBatchExecutionId       INT = NULL;

    --Get running ETLBatch if there is one
    SELECT
      @ETLBatchExecutionId = ETLBatchExecutionId
    FROM
      [dbo].[func_GetRunningETLBatchExecution] (@BatchStartedWithinMinutes, @CallingJobName) eb

    WHILE [dbo].[func_IsSQLAgentJobRunning](@JobNameToWaitFor) = 1
      BEGIN
          SET @EventDescription = 'Waiting for [' + @JobNameToWaitFor + '] job to complete. Wait interval ' + @PollingDelay;

          IF @ETLBatchExecutionId IS NOT NULL
            BEGIN
                EXEC [log].[InsertETLBatchExecutionEvent]
                  10
                 ,@ETLBatchExecutionId
                 ,NULL
                 ,@EventDescription;
            END
          ELSE
            BEGIN
                PRINT @EventDescription;
            END

          WAITFOR DELAY @PollingDelay;
      END

    SET @EndETLBatchExecutionInd = 0;

    RETURN 0 
