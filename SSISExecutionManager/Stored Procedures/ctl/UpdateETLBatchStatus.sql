CREATE PROCEDURE [ctl].[UpdateETLBatchStatus] @ETLBatchExecutionId INT, @ETLBatchExecutionStatusId INT OUTPUT, @ETLBatchPhaseId INT OUTPUT
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
      ,@ETLBatchExecutionStatusId = epb.ETLBatchExecutionStatusId
	  ,@ETLBatchPhaseId = bp.ETLBatchPhaseId
    FROM
      [dbo].[func_GetETLBatchExecutionStatus] (@ETLBatchExecutionId) epb
	  OUTER APPLY [dbo].[func_GetMinIncompleteBatchExecutionPhase] (@ETLBatchExecutionId) bp

    --If the batch has just completed, get the EndDateTime
    SET @EndDateTime = IIF(@EndDateTime IS NULL
                           AND @ETLBatchExecutionStatusId = 5, GETDATE(), NULL)

    --Update the ETLBatch table
    EXEC [ctl].[SaveETLBatchExecution] @ETLBatchExecutionId OUT,@EndDateTime = @EndDateTime,@TotalEntryPointPackageCount = @TotalEntryPointPackageCount,@TotalRemainingEntryPointPackageCount = @TotalRemainingEntryPointPackageCount,@TotalETLPackageCount = @TotalETLPackageCount,@TotalRemainingETLPackageCount = @TotalRemainingETLPackageCount,@ETLBatchStatusId = @ETLBatchExecutionStatusId,@SSISEnvironmentName = NULL, @ETLBatchPhaseId = @ETLBatchPhaseId

    RETURN 0 
