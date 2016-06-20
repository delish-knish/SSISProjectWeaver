CREATE PROCEDURE [ctl].[SaveETLBatchExecution] @ETLBatchExecutionId                      INT OUTPUT,
                                      @SSISEnvironmentName                               VARCHAR(128),
                                      @SQLAgentJobName                                   VARCHAR(128) = NULL,
                                      --@Periodicity                                            CHAR(2) = NULL,
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
             ,@SQLAgentJobName
             --,@Periodicity
             ,@ETLBatchId
             ,@StartDateTime
             ,@EndDateTime
             ,@TotalEntryPointPackageCount
             ,@TotalRemainingEntryPointPackageCount
             ,@TotalETLPackageCount
             ,@TotalRemainingETLPackageCount
             ,@ETLBatchStatusId
			 ,@ETLBatchPhaseId
          ) AS source (ETLBatchExecutionId, SSISEnvironmentName, SQLAgentJobName, ETLBatchId, StartDateTime, EndDateTime, TotalEntryPointPackageCount, TotalRemainingEntryPointPackageCount, TotalETLPackageCount, TotalRemainingETLPackageCount, 
		  ETLBatchStatusId, ETLBatchPhaseId
          )
    ON target.[ETLBatchExecutionId] = source.[ETLBatchExecutionId]
    WHEN Matched THEN
      UPDATE SET SSISEnvironmentName = ISNULL(source.SSISEnvironmentName, target.SSISEnvironmentName)
                 ,SQLAgentJobName = ISNULL(source.SQLAgentJobName, target.SQLAgentJobName)
                 --,Periodicity = ISNULL(source.Periodicity, target.Periodicity)
                 ,ETLBatchId = ISNULL(source.ETLBatchId, target.[ETLBatchId])
                 ,EndDateTime = ISNULL(source.EndDateTime, target.EndDateTime)
                 ,TotalEntryPointPackageCount = ISNULL(source.TotalEntryPointPackageCount, target.TotalEntryPointPackageCount)
                 ,TotalRemainingEntryPointPackageCount = ISNULL(source.TotalRemainingEntryPointPackageCount, target.TotalRemainingEntryPointPackageCount)
                 ,TotalETLPackageCount = ISNULL(source.TotalETLPackageCount, target.TotalETLPackageCount)
                 ,TotalRemainingETLPackageCount = ISNULL(source.TotalRemainingETLPackageCount, target.TotalRemainingETLPackageCount)
                 ,ETLBatchStatusId = ISNULL(source.ETLBatchStatusId, target.ETLBatchStatusId)
				 ,ETLBatchPhaseId = ISNULL(source.ETLBatchPhaseId, target.ETLBatchPhaseId)
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (SSISEnvironmentName
              ,SQLAgentJobName
              --,Periodicity
              ,ETLBatchId
              ,StartDateTime
              ,EndDateTime
              ,TotalEntryPointPackageCount
              ,TotalRemainingEntryPointPackageCount
              ,TotalETLPackageCount
              ,TotalRemainingETLPackageCount
              ,ETLBatchStatusId
			  ,ETLBatchPhaseId
    )
      VALUES(source.SSISEnvironmentName
             ,source.SQLAgentJobName
             --,source.Periodicity
             ,source.ETLBatchId
             ,source.StartDateTime
             ,source.EndDateTime
             ,source.TotalEntryPointPackageCount
             ,source.TotalRemainingEntryPointPackageCount
             ,source.TotalETLPackageCount
             ,source.TotalRemainingETLPackageCount
             ,1 --Created/Ready: Always set to ready on insert
			 ,source.ETLBatchPhaseId
    );

    SET @ETLBatchExecutionId = ISNULL(@ETLBatchExecutionId, SCOPE_IDENTITY())

	--TODO: Clean this up
	IF SCOPE_IDENTITY() IS NOT NULL
	BEGIN
		DECLARE @NewETLBatchPhaseId INT = (SELECT ETLBatchPhaseId FROM dbo.func_GetMinIncompleteBatchExecutionPhase(@ETLBatchExecutionId));
		UPDATE ctl.ETLBatchExecution SET ETLBatchPhaseId = @NewETLBatchPhaseId;
	END

    RETURN 0 
