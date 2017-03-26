CREATE PROCEDURE [ctl].[ExecuteETLBatch] @CallingJobName		VARCHAR(128),
                                         @SSISEnvironmentName	VARCHAR(128),
                                         @ETLBatchId			INT
AS
    SET XACT_ABORT, NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

    --Set up "Constants"
    DECLARE @ETLBatchExecutionCompleteStatusId                   INT = 5,
            @ETLBatchExecutionTimeOutStatusId                    INT = 8,
            @ETLBatchExecutionExceptionStatusId                  INT = 9,
			@ETLBatchExecutionCanceledStatusId					 INT = 10;

    --Set up logging variables
    DECLARE @CurrentDateTime  DATETIME = GETDATE(),
            @EventDescription VARCHAR(MAX);

    --Set up batch variables
    DECLARE @ETLBatchExecutionId				INT,
            @PreviousETLBatchExecutionStatusId	INT,
			@ETLBatchExecutionStatusId			INT = 0;

	--Set up Batch behavior variables
    DECLARE @EndETLBatchExecutionInd BIT = 0;

   WHILE @ETLBatchExecutionStatusId NOT IN (5,8,9) --While batch is not in the "Complete" state, hasn't timed out, and hasn't encountered an exception
   BEGIN
   BEGIN TRY
      --Get values from Config table
      DECLARE @ErrorEmailRecipients      VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Email Recipients - Default') ),
              @BatchStartedWithinMinutes VARCHAR(MAX) = ISNULL((SELECT MinutesBackToContinueBatch FROM ctl.ETLBatch WHERE ETLBatchId = @ETLBatchId), 1440),
              @PollingDelay				 CHAR(8) = ( [dbo].[func_GetConfigurationValue] ('ETL Batch Polling Delay') ),
			  @SendBatchCompleteEmailInd BIT;

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
        BEGIN --The batch has not yet been created
			--Seed the ETLBatchExecution table
            EXEC [ctl].[SaveETLBatchExecution] @ETLBatchExecutionId OUT,@SSISEnvironmentName = @SSISEnvironmentName,@CallingJobName = @CallingJobName,@ETLBatchId = @ETLBatchId,@StartDateTime = @CurrentDateTime,@EndDateTime = NULL,@ETLBatchStatusId = 1;

            SET @EventDescription = 'Batch created';

            EXEC [log].InsertETLBatchEvent 1,@ETLBatchExecutionId,NULL,@EventDescription;

            --Set the ReadyForExecutionInd flag on entry-point packages and packages set to bypass entry-point packages
            EXEC [ctl].[UpdatePackagesToExecuteForBatch] @ETLBatchExecutionId;
        END --End: Create Batch

	  --Run SQLCommands
	  /*TODO: This is invalid because there could be multiple batch pha$es
	  IF @PreviousETLBatchPha$eId <> @ETLBatchPha$eId
	  BEGIN
		DECLARE @SQLCommandCount SMALLINT;
		--If there are "end" SQLCommands for this pha$e then execute them
		SET @SQLCommandCount = [dbo].[func_GetSQLCommandCountForETLBatchPha$e](@PreviousETLBatchPha$eId, NULL, 1);
		IF @SQLCommandCount > 0
              BEGIN
                  EXEC [ctl].[ExecuteETLBatchPha$eSQLCommands] @ETLBatchExecutionId,@PreviousETLBatchPha$eId,NULL,1,@EndETLBatchExecutionInd OUT;

                  SET @EventDescription = 'Executing end of [' + [dbo].[func_GetETLBatchPha$eName](@PreviousETLBatchPha$eId) + '] Pha$e SQL Commands';

                  EXEC [log].InsertETLBatchEvent 16,@ETLBatchExecutionId,NULL,@EventDescription;

                  IF @EndETLBatchExecutionInd = 1
                    BEGIN
                        SET @ETLBatchExecutionStatusId = @ETLBatchExecutionTimeOutStatusId;

                        RETURN;
                    END
              END 

		--If there are "begin" SQLCommands for this pha$e then execute them
		SET @SQLCommandCount = [dbo].[func_GetSQLCommandCountForETLBatchPha$e](@ETLBatchPha$eId, 1, NULL);
		IF @SQLCommandCount > 0
              BEGIN
                  EXEC [ctl].[ExecuteETLBatchPha$eSQLCommands] @ETLBatchExecutionId,@ETLBatchPha$eId,NULL,1,@EndETLBatchExecutionInd OUT;

                  SET @EventDescription = 'Executing begin of [' + [dbo].[func_GetETLBatchPha$eName](@ETLBatchPha$eId) + '] Pha$e SQL Commands';

                  EXEC [log].InsertETLBatchEvent 16,@ETLBatchExecutionId,NULL,@EventDescription;

                  IF @EndETLBatchExecutionInd = 1
                    BEGIN
                        SET @ETLBatchExecutionStatusId = @ETLBatchExecutionTimeOutStatusId;

                        RETURN;
                    END
              END 
	  END */

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

  END
    RETURN 0 
