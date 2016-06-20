CREATE PROCEDURE [ctl].[UpdateETLBatchStatus] @ETLBatchExecutionId INT, @ETLBatchStatusId INT OUTPUT, @ETLBatchPhaseId INT OUTPUT
AS
    DECLARE @EndDateTime                                       DATETIME2 = NULL,
            @TotalEntryPointPackageCount                       SMALLINT = NULL,
            @TotalRemainingEntryPointPackageCount              SMALLINT = NULL,
            @TotalETLPackageCount                              SMALLINT = NULL,
            @TotalRemainingETLPackageCount                     SMALLINT = NULL;

    SELECT
      @TotalEntryPointPackageCount = epb.TotalEntryPointPackageCount
      ,@TotalRemainingEntryPointPackageCount = epb.TotalRemainingEntryPointPackageCount
      ,@TotalETLPackageCount = epb.TotalETLPackageCount
      ,@TotalRemainingETLPackageCount = epb.TotalRemainingETLPackageCount
      ,@TotalETLPackageCount = epb.TotalETLPackageCount
      ,@TotalRemainingETLPackageCount = epb.TotalRemainingETLPackageCount
      ,@ETLBatchStatusId = epb.ETLBatchStatusId
	  ,@ETLBatchPhaseId = bp.ETLBatchPhaseId
    FROM
      [dbo].[func_GetETLBatchStatus] (@ETLBatchExecutionId) epb
	  OUTER APPLY [dbo].[func_GetMinIncompleteBatchExecutionPhase] (@ETLBatchExecutionId) bp

    --If the batch has just completed, get the EndDateTime
    SET @EndDateTime = IIF(@EndDateTime IS NULL
                           AND @ETLBatchStatusId = 5, GETDATE(), NULL)

    --Update the ETLBatch table
    EXEC [ctl].[SaveETLBatchExecution] @ETLBatchExecutionId OUT,@EndDateTime = @EndDateTime,@TotalEntryPointPackageCount = @TotalEntryPointPackageCount,@TotalRemainingEntryPointPackageCount = @TotalRemainingEntryPointPackageCount,@TotalETLPackageCount = @TotalETLPackageCount,@TotalRemainingETLPackageCount = @TotalRemainingETLPackageCount,@ETLBatchStatusId = @ETLBatchStatusId,@SSISEnvironmentName = NULL, @ETLBatchPhaseId = @ETLBatchPhaseId

    RETURN 0 
