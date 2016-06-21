CREATE PROCEDURE [ctl].[ExecuteETLBatch] @SQLAgentJobName		VARCHAR(128),
                                         @SSISEnvironmentName	VARCHAR(128),
                                         --@Periodicity              CHAR(2),
                                         @ETLBatchId			INT
AS
    SET XACT_ABORT, NOCOUNT ON;

    --Set up "Constants"
    DECLARE @ETLBatchCompleteStatusId                   INT = 5,
            @ETLBatchTimeOutStatusId                    INT = 8,
            @ETLBatchExceptionStatusId                  INT = 9;

    --Set up logging variables
    DECLARE @CurrentDateTime  DATETIME = GETDATE(),
            @EventDescription VARCHAR(MAX);

    --Set up batch variables
    DECLARE @ETLBatchExecutionId      INT,
            @PreviousETLBatchStatusId INT,
			@PreviousETLBatchPhaseId	INT,
			@ETLBatchStatusId			INT = 0,
			@ETLBatchPhaseId			INT;

	--Set up Batch behavior variables
    DECLARE @EndETLBatchExecutionInd BIT = 0;

   WHILE @ETLBatchStatusId NOT IN (5,8,9) --While batch is not in the "Complete" state, hasn't timed out, and hasn't encountered an exception
   BEGIN
   BEGIN TRY
      --Get values from Config table
      DECLARE @ErrorEmailRecipients      VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Email Recipients - Default') ),
              @BatchStartedWithinMinutes VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Minutes Back to Continue a Batch') ),
              @PollingDelay				 CHAR(8) = ( [dbo].[func_GetConfigurationValue] ('ETL Batch Polling Delay') );

      --Get running ETLBatch
      SELECT
        @ETLBatchExecutionId = [ETLBatchExecutionId]
        ,@PreviousETLBatchStatusId = ETLBatchStatusId
		,@PreviousETLBatchPhaseId = ETLBatchPhaseId
      FROM
        [dbo].[func_GetRunningETLBatch] (@BatchStartedWithinMinutes, @SQLAgentJobName) eb;

	  SET @PreviousETLBatchPhaseId = ISNULL(@PreviousETLBatchPhaseId,-1);

      --The batch is already running
      IF @ETLBatchExecutionId IS NOT NULL
        BEGIN
            --Update the batch with statuses that have changed since the last execution of this proc
            EXEC [ctl].[UpdateETLBatchStatus] @ETLBatchExecutionId = @ETLBatchExecutionId,@ETLBatchStatusId = @ETLBatchStatusId OUT, @ETLBatchPhaseId = @ETLBatchPhaseId OUT;

            --Log any errors found in the SSISDB
            DECLARE @ErrorsRequiringNotificationCount INT,
                    @ETLPackagesRequiringRestartCount INT;

            EXEC [log].SaveETLPackageExecutionErrors @ETLBatchExecutionId,@ErrorsRequiringNotificationCount OUT,@ETLPackagesRequiringRestartCount OUT;

            --If there are errors that have not had notifications sent, send them
            IF @ErrorsRequiringNotificationCount > 0
              BEGIN
                  EXEC ctl.SendErrorNotificationsForETLBatch @ETLBatchExecutionId,@ErrorEmailRecipients;

                  SET @EventDescription = 'Error Notification(s) Sent (' + CAST(@ErrorsRequiringNotificationCount AS VARCHAR(10)) + ')';

                  EXEC [log].InsertETLBatchEvent 7,@ETLBatchExecutionId,NULL,@EventDescription;
              END

            --If there are packages that require restart, flag them for restart (this is determined when executing SaveETLPackageExecutionErrors)
            IF @ETLPackagesRequiringRestartCount > 0
              EXEC ctl.RestartETLPackagesForETLBatch @ETLBatchExecutionId,@ErrorEmailRecipients;

            --The batch has just been marked as complete
            IF @ETLBatchStatusId = @ETLBatchCompleteStatusId --Was already completed or has just completed 
              BEGIN
                  --Archive the execution stats of the packages for the batch
                  EXEC [log].SaveETLPackageExecutions @ETLBatchExecutionId = @ETLBatchExecutionId;

                  SET @EventDescription = 'Batch completed';

                  EXEC [log].InsertETLBatchEvent 5,@ETLBatchExecutionId,NULL,@EventDescription;
              END
        END --End: The batch is already running
      ELSE 
        BEGIN --The batch has not yet been created
			--Seed the ETLBatchExecution table
            EXEC [ctl].[SaveETLBatchExecution] @ETLBatchExecutionId OUT,@SSISEnvironmentName = @SSISEnvironmentName,@SQLAgentJobName = @SQLAgentJobName,@ETLBatchId = @ETLBatchId,@StartDateTime = @CurrentDateTime,@EndDateTime = NULL,@ETLBatchStatusId = 1;

            --Set ETLBatchPhaseId
			SET @ETLBatchPhaseId = (SELECT ETLBatchPhaseId FROM dbo.func_GetMinIncompleteBatchExecutionPhase(@ETLBatchExecutionId));
			
            SET @EventDescription = 'Batch created';

            EXEC [log].InsertETLBatchEvent 1,@ETLBatchExecutionId,NULL,@EventDescription;

            --Set the ReadyForExecutionInd flag on entry-point packages and packages set to bypass entry-point packages
            EXEC [ctl].[UpdatePackagesToExecuteForBatch] @ETLBatchExecutionId;
        END --End: Create Batch

	  --Run SQLCommands
	  IF @PreviousETLBatchPhaseId <> @ETLBatchPhaseId
	  BEGIN
		DECLARE @SQLCommandCount SMALLINT;
		--If there are "end" SQLCommands for this phase then execute them
		SET @SQLCommandCount = [dbo].[func_GetSQLCommandCountForETLBatchPhase](@PreviousETLBatchPhaseId, NULL, 1);
		IF @SQLCommandCount > 0
              BEGIN
                  EXEC [ctl].[ExecuteETLBatchPhaseSQLCommands] @ETLBatchExecutionId,@PreviousETLBatchPhaseId,NULL,1,@EndETLBatchExecutionInd OUT;

                  SET @EventDescription = 'Executing end of [' + [dbo].[func_GetETLBatchPhaseName](@PreviousETLBatchPhaseId) + '] Phase SQL Commands';

                  EXEC [log].InsertETLBatchEvent 16,@ETLBatchExecutionId,NULL,@EventDescription;

                  IF @EndETLBatchExecutionInd = 1
                    BEGIN
                        SET @ETLBatchStatusId = @ETLBatchTimeOutStatusId;

                        RETURN;
                    END
              END 

		--If there are "begin" SQLCommands for this phase then execute them
		SET @SQLCommandCount = [dbo].[func_GetSQLCommandCountForETLBatchPhase](@ETLBatchPhaseId, 1, NULL);
		IF @SQLCommandCount > 0
              BEGIN
                  EXEC [ctl].[ExecuteETLBatchPhaseSQLCommands] @ETLBatchExecutionId,@ETLBatchPhaseId,NULL,1,@EndETLBatchExecutionInd OUT;

                  SET @EventDescription = 'Executing begin of [' + [dbo].[func_GetETLBatchPhaseName](@ETLBatchPhaseId) + '] Phase SQL Commands';

                  EXEC [log].InsertETLBatchEvent 16,@ETLBatchExecutionId,NULL,@EventDescription;

                  IF @EndETLBatchExecutionInd = 1
                    BEGIN
                        SET @ETLBatchStatusId = @ETLBatchTimeOutStatusId;

                        RETURN;
                    END
              END 
	  END

      --The batch is in progress. Run all packages ready for execution.
      IF @ETLBatchExecutionId IS NOT NULL
         AND @ETLBatchStatusId <> @ETLBatchCompleteStatusId
        BEGIN
            SET @EventDescription = 'Identifying packages to execute';

            EXEC [log].InsertETLBatchEvent 2,@ETLBatchExecutionId,NULL,@EventDescription;

            --Execute packages that are ready
            EXEC [ctl].[ExecuteETLPackagesForBatch] @ETLBatchExecutionId,@SSISEnvironmentName;
        END --End: Run all packages ready for execution

      SET @ETLBatchStatusId = ( dbo.func_GetETLBatchStatusId(@ETLBatchExecutionId) );

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

  IF @ETLBatchStatusId NOT IN (5,8,9)
			WAITFOR DELAY @PollingDelay;

  END
    RETURN 0 
