CREATE PROCEDURE [ctl].[ExecuteETLBatch] @SQLAgentJobName     VARCHAR(128),
                                         @SSISEnvironmentName VARCHAR(128),
                                         --@Periodicity              CHAR(2),
                                         @ETLPackageSetId     INT = NULL,
                                         @SQLCommandSetId     INT = NULL,
                                         @ETLBatchStatusId    INT OUT
--@HourlyInd           BIT
AS
  BEGIN TRY
      SET XACT_ABORT, NOCOUNT ON;

      --Set up "Constants"
      DECLARE @ETLBatchCompleteStatusId                   INT = 5,
              @ETLBatchCriticalPathPackagesComplete       INT = 6,
              @ETLBatchTimeOutStatusId                    INT = 8,
              @ETLBatchExceptionStatusId                  INT = 9,
              @DailyPeriodicityTypeId                     INT = 1,
              @HourlyPeriodicityTypeId                    INT = 2,
              @PostLoadSQLCommandDependencyTypeId         INT = 1,
              @ETLBatchCreateSQLCommandDependencyTypeId   INT = 2,
              @ETLBatchCompleteSQLCommandDependencyTypeId INT = 3;

      --Set up logging variables
      DECLARE @CurrentDateTime  DATETIME = GETDATE(),
              @EventDescription VARCHAR(MAX);

      --Set up batch variables
      DECLARE @ETLBatchId               INT,
              @PreviousETLBatchStatusId INT

      --Get values from Config table
      DECLARE @ErrorEmailRecipients      VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Email Recipients - Default') ),
              @BatchStartedWithinMinutes VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Minutes Back to Continue a Batch') );

      --Set up Batch behavior variables
      DECLARE @EndETLBatchExecutionInd BIT = 0;

      --Get running ETLBatch
      SELECT
        @ETLBatchId = ETLBatchId
        ,@PreviousETLBatchStatusId = ETLBatchStatusId
      FROM
        [dbo].[func_GetRunningETLBatch] (@BatchStartedWithinMinutes, @SQLAgentJobName) eb

      --The batch is already running
      IF @ETLBatchId IS NOT NULL
        BEGIN
            --Update the batch with statuses that have changed since the last execution of this proc
            EXEC [ctl].[UpdateETLBatchStatus] @ETLBatchId = @ETLBatchId,@ETLBatchStatusId = @ETLBatchStatusId OUT;

            --Log any errors found in the SSISDB
            DECLARE @ErrorsRequiringNotificationCount INT,
                    @ETLPackagesRequiringRestartCount INT;

            EXEC [log].SaveETLPackageExecutionErrors @ETLBatchId,@ErrorsRequiringNotificationCount OUT,@ETLPackagesRequiringRestartCount OUT;

            --If there are errors that have not had notifications sent, send them
            IF @ErrorsRequiringNotificationCount > 0
              BEGIN
                  EXEC ctl.SendErrorNotificationsForETLBatch @ETLBatchId,@ErrorEmailRecipients;

                  SET @EventDescription = 'Error Notification(s) Sent (' + CAST(@ErrorsRequiringNotificationCount AS VARCHAR(10)) + ')';

                  EXEC [log].InsertETLBatchEvent 7,@ETLBatchId,NULL,@EventDescription;
              END

            --If there are packages that require restart, flag them for restart (this is determined when executing SaveETLPackageExecutionErrors)
            IF @ETLPackagesRequiringRestartCount > 0
              EXEC ctl.RestartETLPackagesForETLBatch @ETLBatchId,@ErrorEmailRecipients;


            --The first time all critical path packages have completed
            IF @PreviousETLBatchStatusId NOT IN ( @ETLBatchCompleteStatusId, @ETLBatchCriticalPathPackagesComplete )
               AND @ETLBatchStatusId IN ( @ETLBatchCompleteStatusId, @ETLBatchCriticalPathPackagesComplete ) --Critical path packages have completed for the first time (need to check 5 and 6 because it is possible that all packages are critical path in which case a status of 6 would never occur
              BEGIN
                  SET @EventDescription = 'Critical path packages complete';

                  EXEC [log].InsertETLBatchEvent 6,@ETLBatchId,NULL,@EventDescription;

                  --Execute post-critical path SQL Commands (jobs, triggers, etc.) 
                  IF @SQLCommandSetId IS NOT NULL
                    BEGIN
                        EXEC [ctl].[ExecuteSQLCommandSet] @ETLBatchId,@SQLCommandSetId,@PostLoadSQLCommandDependencyTypeId,@EndETLBatchExecutionInd OUT

                        SET @EventDescription = 'Post-critical path SQL Commands executed';

                        EXEC [log].InsertETLBatchEvent 8,@ETLBatchId,NULL,@EventDescription;

                        IF @EndETLBatchExecutionInd = 1
                          BEGIN
                              SET @ETLBatchStatusId = @ETLBatchTimeOutStatusId;

                              RETURN;
                          END
                    END
              END

            --The batch has just been marked as complete
            IF @ETLBatchStatusId = @ETLBatchCompleteStatusId --Was already completed or has just completed 
              BEGIN
                  --Archive the execution stats of the packages for the batch
                  EXEC [log].SaveETLPackageExecutions @ETLBatchId = @ETLBatchId;

                  --Execute ETL Batch Complete SQL Commands
                  IF @SQLCommandSetId IS NOT NULL
                    BEGIN
                        EXEC [ctl].[ExecuteSQLCommandSet] @ETLBatchId,@SQLCommandSetId,@ETLBatchCompleteSQLCommandDependencyTypeId,@EndETLBatchExecutionInd OUT

                        SET @EventDescription = 'ETL Batch Complete SQL Commands executed';

                        EXEC [log].InsertETLBatchEvent 16,@ETLBatchId,NULL,@EventDescription;

                        IF @EndETLBatchExecutionInd = 1
                          BEGIN
                              SET @ETLBatchStatusId = @ETLBatchTimeOutStatusId;

                              RETURN;
                          END
                    END

                  SET @EventDescription = 'Batch completed';

                  EXEC [log].InsertETLBatchEvent 5,@ETLBatchId,NULL,@EventDescription;
              END
        END --End: The batch is already running
      ELSE --The batch has not yet been created
        BEGIN
            --Seed the ETLBatch table
            EXEC [ctl].SaveETLBatch @ETLBatchId OUT,@SSISEnvironmentName = @SSISEnvironmentName,@SQLAgentJobName = @SQLAgentJobName,@ETLPackageSetId = @ETLPackageSetId,@StartDateTime = @CurrentDateTime,@EndDateTime = NULL,@ETLBatchStatusId = 1;

            SET @EventDescription = 'Batch created';

            EXEC [log].InsertETLBatchEvent 1,@ETLBatchId,NULL,@EventDescription;

            --Run ETL Batch Creation SQL Commands
            IF @SQLCommandSetId IS NOT NULL
              BEGIN
                  EXEC [ctl].[ExecuteSQLCommandSet] @ETLBatchId,@SQLCommandSetId,@ETLBatchCreateSQLCommandDependencyTypeId,@EndETLBatchExecutionInd OUT;

                  SET @EventDescription = 'ETL Batch Create SQL Commands executed';

                  EXEC [log].InsertETLBatchEvent 17,@ETLBatchId,NULL,@EventDescription;

                  IF @EndETLBatchExecutionInd = 1
                    BEGIN
                        SET @ETLBatchStatusId = @ETLBatchTimeOutStatusId;

                        RETURN;
                    END
              END

            --Set the ReadyForExecutionInd flag on entry-point packages and packages set to bypass entry-point packages
            EXEC [ctl].[UpdatePackagesToExecuteForBatch] @ETLBatchId;
        END --End: Create Batch

      --The batch is in progress. Run all packages ready for execution.
      IF @ETLBatchId IS NOT NULL
         AND @ETLBatchStatusId <> @ETLBatchCompleteStatusId
        BEGIN
            SET @EventDescription = 'Identifying packages to execute';

            EXEC [log].InsertETLBatchEvent 2,@ETLBatchId,NULL,@EventDescription;

            --Execute packages that are ready
            EXEC [ctl].[ExecuteETLPackagesForBatch] @ETLBatchId,@SSISEnvironmentName;
        END --End: Run all packages ready for execution

      --Set the output parameter so that the calling process knows the status of the batch
      SET @ETLBatchStatusId = ( dbo.func_GetETLBatchStatusId(@ETLBatchId) );

  END TRY

  BEGIN CATCH
      --Log the exception
      SET @EventDescription = 'Error: ' + ERROR_MESSAGE();

      EXEC [log].InsertETLBatchEvent 4,@ETLBatchId,NULL,@EventDescription;

      --Log Error in addition to the batch event so that we get a notification
      EXEC [ctl].[InsertUnhandledError] @ETLBatchId,@EventDescription;

      --If Daily batch then throw the exception -> manual intervention will be required. Directly notify because the job is no longer running and will not email the exception
      IF @ETLPackageSetId IN ( 1, 2 ) --Daily TODO: fix this crap
        THROW
      ELSE  -- If hourly, send error emails, end the batch and mark as "Exception". TODO: also fix this crap
        BEGIN
            EXEC ctl.SendErrorNotificationsForETLBatch @ETLBatchId,@ErrorEmailRecipients;

            SET @EventDescription = 'Error Notification(s) Sent (' + CAST(@ErrorsRequiringNotificationCount AS VARCHAR(10)) + ')';

            EXEC [log].InsertETLBatchEvent 7,@ETLBatchId,NULL,@EventDescription;

            SET @ETLBatchStatusId = @ETLBatchExceptionStatusId;

            EXEC [ctl].[EndETLBatch] @ETLBatchId = @ETLBatchId,@ETLBatchStatusId = @ETLBatchExceptionStatusId;

            RETURN;
        END
  END CATCH

    RETURN 0 
