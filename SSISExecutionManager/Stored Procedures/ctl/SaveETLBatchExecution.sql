CREATE PROCEDURE [ctl].[SaveETLBatchExecution] @ETLBatchExecutionId                      INT OUTPUT,
                                      @SSISEnvironmentName                               VARCHAR(128) = NULL,
                                      @CallingJobName                                   VARCHAR(128) = NULL,
                                      @ETLBatchId										 INT = NULL,
                                      @StartDateTime                                     DATETIME2 = NULL,
                                      @EndDateTime                                       DATETIME2 = NULL,
                                      @TotalEntryPointPackageCount                       SMALLINT = NULL,
                                      @TotalRemainingEntryPointPackageCount              SMALLINT = NULL,
                                      @TotalETLPackageCount                              SMALLINT = NULL,
                                      @TotalRemainingETLPackageCount                     SMALLINT = NULL,
                                      @ETLBatchStatusId                                  INT = NULL
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
          ) AS source (ETLBatchExecutionId, SSISEnvironmentName, CallingJobName, ETLBatchId, StartDateTime, EndDateTime, TotalEntryPointPackageCount, TotalRemainingEntryPointPackageCount, TotalETLPackageCount, TotalRemainingETLPackageCount, 
		  ETLBatchStatusId
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
    );

    SET @ETLBatchExecutionId = ISNULL(@ETLBatchExecutionId, SCOPE_IDENTITY())

    RETURN 0 
