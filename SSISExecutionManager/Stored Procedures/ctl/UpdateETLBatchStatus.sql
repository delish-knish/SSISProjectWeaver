CREATE PROCEDURE [ctl].[UpdateETLBatchStatus] @ETLBatchExecutionId       INT,
                                              @ETLBatchExecutionStatusId INT OUTPUT
AS
    DECLARE @EndDateTime                           DATETIME2 = NULL
            ,@TotalEntryPointPackageCount          SMALLINT = NULL
            ,@TotalRemainingEntryPointPackageCount SMALLINT = NULL
            ,@TotalETLPackageCount                 SMALLINT = NULL
            ,@TotalRemainingETLPackageCount        SMALLINT = NULL
            ,@ETLBatchExecutionCompleteStatusId    INT = 5
            ,@ETLBatchExecutionCanceledStatusId    INT = 10
			,@ETLBatchExecutionCurrentStatusId	   INT = (SELECT ETLBatchStatusId FROM ctl.ETLBatchExecution WHERE ETLBatchExecutionId = @ETLBatchExecutionId);

	IF @ETLBatchExecutionCurrentStatusId <> @ETLBatchExecutionCanceledStatusId --The batch was canceled outside of normal processing and we don't want the running process to override/overwrite this
	BEGIN
		SELECT
		  @TotalEntryPointPackageCount = epb.TotalEntryPointPackageCount
		 ,@TotalRemainingEntryPointPackageCount = epb.TotalRemainingEntryPointPackageCount
		 ,@TotalETLPackageCount = epb.TotalETLPackageCount
		 ,@TotalRemainingETLPackageCount = epb.TotalRemainingETLPackageCount
		 ,@TotalETLPackageCount = epb.TotalETLPackageCount
		 ,@TotalRemainingETLPackageCount = epb.TotalRemainingETLPackageCount
		 ,@ETLBatchExecutionStatusId = epb.ETLBatchExecutionStatusId
		FROM
		  [dbo].[func_GetETLBatchExecutionStatus] (@ETLBatchExecutionId) epb

		--If the batch has just completed, get the EndDateTime
		SET @EndDateTime = IIF(@EndDateTime IS NULL
							   AND @ETLBatchExecutionStatusId IN (@ETLBatchExecutionCompleteStatusId, @ETLBatchExecutionCanceledStatusId), GETDATE(), NULL)

		--Update the ETLBatch table
		EXEC [ctl].[SaveETLBatchExecution]
		  @ETLBatchExecutionId OUT
		 ,@EndDateTime = @EndDateTime
		 ,@TotalEntryPointPackageCount = @TotalEntryPointPackageCount
		 ,@TotalRemainingEntryPointPackageCount = @TotalRemainingEntryPointPackageCount
		 ,@TotalETLPackageCount = @TotalETLPackageCount
		 ,@TotalRemainingETLPackageCount = @TotalRemainingETLPackageCount
		 ,@ETLBatchStatusId = @ETLBatchExecutionStatusId
		 ,@SSISEnvironmentName = NULL
	END

    RETURN 0 
