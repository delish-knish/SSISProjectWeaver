CREATE PROCEDURE [ctl].[UpdateETLBatchStatus] @ETLBatchId INT, @ETLBatchStatusId INT OUTPUT
AS
    DECLARE @EndDateTime                                       DATETIME2 = NULL,
            @TotalEntryPointPackageCount                       SMALLINT = NULL,
            @TotalRemainingEntryPointPackageCount              SMALLINT = NULL,
            @TotalETLPackageCount                              SMALLINT = NULL,
            @TotalRemainingETLPackageCount                     SMALLINT = NULL,
            @CriticalPathPostTransformRemainingETLPackageCount SMALLINT= NULL,
            @CriticalPathPostLoadRemainingETLPackageCount      SMALLINT = NULL,
			@PostTransformStartDateTime DATETIME2 = NULL;

    SELECT
      @TotalEntryPointPackageCount = epb.TotalEntryPointPackageCount
      ,@TotalRemainingEntryPointPackageCount = epb.TotalRemainingEntryPointPackageCount
      ,@TotalETLPackageCount = epb.TotalETLPackageCount
      ,@TotalRemainingETLPackageCount = epb.TotalRemainingETLPackageCount
      ,@CriticalPathPostTransformRemainingETLPackageCount = epb.CriticalPathPostTransformRemainingETLPackageCount
      ,@CriticalPathPostLoadRemainingETLPackageCount = epb.CriticalPathPostLoadRemainingETLPackageCount
      ,@TotalETLPackageCount = epb.TotalETLPackageCount
      ,@TotalRemainingETLPackageCount = epb.TotalRemainingETLPackageCount
      ,@ETLBatchStatusId = epb.ETLBatchStatusId
    FROM
      [dbo].[func_GetETLBatchStatus] (@ETLBatchId) epb

    --If the batch has just completed, get the EndDateTime
    SET @EndDateTime = IIF(@EndDateTime IS NULL
                           AND @ETLBatchStatusId IN ( 5, 6 ), GETDATE(), NULL)

	--If we have just reached the post-transform sequence, set the timestamp
	--SET @PostTransformStartDateTime = IIF(@PostTransformStartDateTime IS NULL AND @CriticalPathPostTransformRemainingETLPackageCount = 0, GETDATE(), NULL)

    --Update the ETLBatch table
    EXEC [ctl].SaveETLBatch @ETLBatchId OUT,@EndDateTime = @EndDateTime,@TotalEntryPointPackageCount = @TotalEntryPointPackageCount,@TotalRemainingEntryPointPackageCount = @TotalRemainingEntryPointPackageCount,@TotalETLPackageCount = @TotalETLPackageCount,@TotalRemainingETLPackageCount = @TotalRemainingETLPackageCount,@CriticalPathPostTransformRemainingETLPackageCount = @CriticalPathPostTransformRemainingETLPackageCount,@CriticalPathPostLoadRemainingETLPackageCount = @CriticalPathPostLoadRemainingETLPackageCount,@ETLBatchStatusId = @ETLBatchStatusId,@SSISEnvironmentName = NULL

    RETURN 0 
