CREATE PROCEDURE [ctl].[SaveETLBatchExecution] @ETLBatchExecutionId                      INT OUTPUT,
                                      @SSISEnvironmentName                               VARCHAR(128),
                                      @CallingJobName                                   VARCHAR(128) = NULL,
                                      @ETLBatchId										 INT = NULL,
                                      @StartDateTime                                     DATETIME2 = NULL,
                                      @EndDateTime                                       DATETIME2 = NULL,
                                      @TotalEntryPointPackageCount                       SMALLINT = NULL,
                                      @TotalRemainingEntryPointPackageCount              SMALLINT = NULL,
                                      @TotalETLPackageCount                              SMALLINT = NULL,
                                      @TotalRemainingETLPackageCount                     SMALLINT = NULL,
                                      @ETLBatchStatusId                                  INT = NULL,
									  @ETLBatchPhaseId									 INT = NULL
AS
    MERGE [ctl].[ETLBatchExecution] AS Target
    USING (SELECT
             @ETLBatchExecutionId
             ,@SSISEnvironmentName
             ,@CallingJobName
             ,@ETLBatchId
             ,@StartDateTime
             ,@EndDateTime
             ,@TotalEntryPointPackageCount
             ,@TotalRemainingEntryPointPackageCount
             ,@TotalETLPackageCount
             ,@TotalRemainingETLPackageCount
             ,@ETLBatchStatusId
			 ,@ETLBatchPhaseId
          ) AS source (ETLBatchExecutionId, SSISEnvironmentName, CallingJobName, ETLBatchId, StartDateTime, EndDateTime, TotalEntryPointPackageCount, TotalRemainingEntryPointPackageCount, TotalETLPackageCount, TotalRemainingETLPackageCount, 
		  ETLBatchStatusId, ETLBatchPhaseId
          )
    ON target.[ETLBatchExecutionId] = source.[ETLBatchExecutionId]
    WHEN Matched THEN
      UPDATE SET SSISEnvironmentName = ISNULL(source.SSISEnvironmentName, target.SSISEnvironmentName)
                 ,CallingJobName = ISNULL(source.CallingJobName, target.CallingJobName)
                 ,ETLBatchId = ISNULL(source.ETLBatchId, target.[ETLBatchId])
                 ,EndDateTime = ISNULL(source.EndDateTime, target.EndDateTime)
                 ,TotalEntryPointPackageCount = ISNULL(source.TotalEntryPointPackageCount, target.TotalEntryPointPackageCount)
                 ,TotalRemainingEntryPointPackageCount = ISNULL(source.TotalRemainingEntryPointPackageCount, target.TotalRemainingEntryPointPackageCount)
                 ,TotalETLPackageCount = ISNULL(source.TotalETLPackageCount, target.TotalETLPackageCount)
                 ,TotalRemainingETLPackageCount = ISNULL(source.TotalRemainingETLPackageCount, target.TotalRemainingETLPackageCount)
                 ,ETLBatchStatusId = ISNULL(source.ETLBatchStatusId, target.ETLBatchStatusId)
				 --,ETLBatchPhaseId = ISNULL(source.ETLBatchPhaseId, target.ETLBatchPhaseId)
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (SSISEnvironmentName
              ,CallingJobName
              ,ETLBatchId
              ,StartDateTime
              ,EndDateTime
              ,TotalEntryPointPackageCount
              ,TotalRemainingEntryPointPackageCount
              ,TotalETLPackageCount
              ,TotalRemainingETLPackageCount
              ,ETLBatchStatusId
			  --,ETLBatchPhaseId
    )
      VALUES(source.SSISEnvironmentName
             ,source.CallingJobName
             ,source.ETLBatchId
             ,source.StartDateTime
             ,source.EndDateTime
             ,source.TotalEntryPointPackageCount
             ,source.TotalRemainingEntryPointPackageCount
             ,source.TotalETLPackageCount
             ,source.TotalRemainingETLPackageCount
             ,1 --Created/Ready: Always set to ready on insert
			 --,source.ETLBatchPhaseId
    );

    SET @ETLBatchExecutionId = ISNULL(@ETLBatchExecutionId, SCOPE_IDENTITY())

	/*TODO: Clean this up
	IF SCOPE_IDENTITY() IS NOT NULL
	BEGIN
		DECLARE @NewETLBatchPhaseId INT = (SELECT ETLBatchPhaseId FROM dbo.func_GetMinIncompleteBatchExecutionPhase(@ETLBatchExecutionId));
		UPDATE ctl.ETLBatchExecution SET ETLBatchPhaseId = @NewETLBatchPhaseId WHERE ETLBatchExecutionId = @ETLBatchExecutionId;
	END */

    RETURN 0 
