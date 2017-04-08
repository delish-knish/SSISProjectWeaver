﻿CREATE PROCEDURE [ctl].[ExecuteETLBatch] @CallingJobName		VARCHAR(128),
                                         @SSISEnvironmentName	VARCHAR(128),
                                         @ETLBatchId			INT
AS
    SET XACT_ABORT, NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

    --Set up "Constants"
    DECLARE @ETLBatchExecutionCompleteStatusId                   INT = 5,
            @ETLBatchExecutionTimeOutStatusId                    INT = 8,
            @ETLBatchExecutionExceptionStatusId                  INT = 9,
			@ETLBatchExecutionCanceledStatusId					 INT = 10,
			@ETLBatchExecutionAutoCanceledStatusId				 INT = 11;

    --Set up batch variables
    DECLARE @ETLBatchExecutionStatusId			INT = 0;

	--Set up Batch behavior variables
    DECLARE @EndETLBatchExecutionInd BIT = 0,
			@LoopCounter			 INT = 0;

   WHILE @ETLBatchExecutionStatusId NOT IN (5,8,9) --While batch is not in the "Complete" state, hasn't timed out, and hasn't encountered an exception
   BEGIN
   BEGIN TRY
      --Get values from Config table
      DECLARE @ETLBatchExecutionId					INT = NULL,
              @PreviousETLBatchExecutionStatusId	INT = NULL,
			  @ErrorEmailRecipients					VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Email Recipients - Default') ),
              @BatchStartedWithinMinutes			VARCHAR(MAX) = ISNULL((SELECT MinutesBackToContinueBatch FROM ctl.ETLBatch WHERE ETLBatchId = @ETLBatchId), 1440),
              @PollingDelay							CHAR(8) = ( [dbo].[func_GetConfigurationValue] ('ETL Batch Polling Delay') ),
			  @SendBatchCompleteEmailInd			BIT;

	  --Set up logging variables
      DECLARE @CurrentDateTime  DATETIME = GETDATE(),
              @EventDescription VARCHAR(MAX);

      --Get running ETLBatch
      SELECT
        @ETLBatchExecutionId = ETLBatchExecutionId
        ,@PreviousETLBatchExecutionStatusId = ETLBatchStatusId
		,@SendBatchCompleteEmailInd = SendBatchCompleteEmailInd
      FROM
        [dbo].[func_GetRunningETLBatchExecution] (@BatchStartedWithinMinutes, @CallingJobName) eb;

      --The batch is already running
      IF @ETLBatchExecutionId IS NOT NULL
        BEGIN
            --Update the batch with statuses that have changed since the last execution of this proc
            EXEC [ctl].[UpdateETLBatchStatus] @ETLBatchExecutionId = @ETLBatchExecutionId,@ETLBatchExecutionStatusId = @ETLBatchExecutionStatusId OUT;

            --Log any errors found in the SSISDB
            DECLARE @ErrorsRequiringNotificationCount INT,
                    @ETLPackagesRequiringRestartCount INT;

            EXEC [log].SaveETLPackageExecutionErrors @ETLBatchExecutionId,@ErrorsRequiringNotificationCount OUT,@ETLPackagesRequiringRestartCount OUT;

            --If there are errors that have not had notifications sent, send them
            IF @ErrorsRequiringNotificationCount > 0
              BEGIN
                  EXEC ctl.[SendErrorNotificationsForETLBatchExecution] @ETLBatchExecutionId,@ErrorEmailRecipients;

                  SET @EventDescription = 'Error Notification(s) Sent (' + CAST(@ErrorsRequiringNotificationCount AS VARCHAR(10)) + ')';

                  EXEC [log].InsertETLBatchEvent 7,@ETLBatchExecutionId,NULL,@EventDescription;
              END

            --If there are packages that require restart, flag them for restart (this is determined when executing SaveETLPackageExecutionErrors)
            IF @ETLPackagesRequiringRestartCount > 0
              EXEC ctl.[RestartETLPackagesForETLBatchExecution] @ETLBatchExecutionId,@ErrorEmailRecipients;

            --The batch has just been marked as complete
            IF @ETLBatchExecutionStatusId IN (@ETLBatchExecutionCompleteStatusId, @ETLBatchExecutionCanceledStatusId) --Was already completed, has just completed, or was manually canceled 
              BEGIN
                  --Archive the execution stats of the packages for the batch
                  EXEC [log].SaveETLPackageExecutions @ETLBatchExecutionId = @ETLBatchExecutionId;

                  IF @ETLBatchExecutionStatusId = @ETLBatchExecutionCompleteStatusId
				  BEGIN
					SET @EventDescription = 'Batch completed';

					EXEC [log].InsertETLBatchEvent 5,@ETLBatchExecutionId,NULL,@EventDescription;
				  END
				  ELSE --Canceled
				  BEGIN
					SET @EventDescription = 'Batch canceled';

					EXEC [log].InsertETLBatchEvent 6,@ETLBatchExecutionId,NULL,@EventDescription;
				  END

				  IF @SendBatchCompleteEmailInd = 1
					EXEC [ops].[SendCompletedBatchExecutionStatistics] @ETLBatchExecutionId;

				  BREAK;
              END
        END --End: The batch is already running
      ELSE 
        BEGIN --The batch has not yet been created or it has been manually canceled
			 --End the batch if it was manually canceled
			IF @LoopCounter > 0 and @ETLBatchExecutionId IS NULL --The proc has been running for at least one iteration but there are no open batches of this type
			BEGIN
				BREAK;
			END
			ELSE
			BEGIN
				--Cancel any "open" batches of the same type 
				--TODO: Create proc which loops through open batches and calls ctl.EndETLBatchExecution proc
				 UPDATE ctl.[ETLBatchExecution]
				 SET ETLBatchStatusId = @ETLBatchExecutionAutoCanceledStatusId
					,EndDateTime = GETDATE()
					,LastUpdatedDate = GETDATE()
					,LastUpdatedUser = SUSER_SNAME()
				 WHERE
					ETLBatchId = @ETLBatchId
					AND EndDateTime IS NULL

				--Seed the ETLBatchExecution table
				EXEC [ctl].[SaveETLBatchExecution] @ETLBatchExecutionId OUT,@SSISEnvironmentName = @SSISEnvironmentName,@CallingJobName = @CallingJobName,@ETLBatchId = @ETLBatchId,@StartDateTime = @CurrentDateTime,@EndDateTime = NULL,@ETLBatchStatusId = 1;

				SET @EventDescription = 'Batch created';

				EXEC [log].InsertETLBatchEvent 1,@ETLBatchExecutionId,NULL,@EventDescription;

				--Set the ReadyForExecutionInd flag on entry-point packages and packages set to bypass entry-point packages
				EXEC [ctl].[UpdatePackagesToExecuteForBatch] @ETLBatchExecutionId;
			END
        END --End: Create Batch

      --The batch is in progress. Run all packages ready for execution.
      IF @ETLBatchExecutionId IS NOT NULL
         AND @ETLBatchExecutionStatusId NOT IN (@ETLBatchExecutionCompleteStatusId, @ETLBatchExecutionCanceledStatusId)
        BEGIN
            SET @EventDescription = 'Identifying packages to execute';

            EXEC [log].InsertETLBatchEvent 2,@ETLBatchExecutionId,NULL,@EventDescription;

            --Execute packages that are ready
            EXEC [ctl].[ExecuteETLPackagesForBatchExecution] @ETLBatchExecutionId,@SSISEnvironmentName;
        END --End: Run all packages ready for execution

      SET @ETLBatchExecutionStatusId = ( dbo.func_GetETLBatchStatusId(@ETLBatchExecutionId) );

  END TRY

  BEGIN CATCH
      --Log the exception
      SET @EventDescription = 'Error: ' + ERROR_MESSAGE();

      EXEC [log].InsertETLBatchEvent 4,@ETLBatchExecutionId,NULL,@EventDescription;

      --Log Error in addition to the batch event so that we get a notification
      EXEC [ctl].[InsertUnhandledError] @ETLBatchExecutionId,@EventDescription;

      --Throw the exception -> manual intervention will be required. 
      THROW
  END CATCH

  IF @ETLBatchExecutionStatusId NOT IN (5,8,9)
			WAITFOR DELAY @PollingDelay;

  SET @LoopCounter = @LoopCounter + 1

  END
    RETURN 0 
