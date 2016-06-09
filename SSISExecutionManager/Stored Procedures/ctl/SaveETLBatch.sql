CREATE PROCEDURE [ctl].[SaveETLBatch] @ETLBatchId                                        INT OUTPUT,
                                      @SSISEnvironmentName                               VARCHAR(128),
                                      @SQLAgentJobName                                   VARCHAR(128) = NULL,
                                      --@Periodicity                                            CHAR(2) = NULL,
                                      @ETLPackageSetId                                   INT = NULL,
                                      @StartDateTime                                     DATETIME2 = NULL,
                                      @EndDateTime                                       DATETIME2 = NULL,
                                      @TotalEntryPointPackageCount                       SMALLINT = NULL,
                                      @TotalRemainingEntryPointPackageCount              SMALLINT = NULL,
                                      @TotalETLPackageCount                              SMALLINT = NULL,
                                      @TotalRemainingETLPackageCount                     SMALLINT = NULL,
                                      @CriticalPathPostTransformRemainingETLPackageCount SMALLINT= NULL,
                                      @CriticalPathPostLoadRemainingETLPackageCount      SMALLINT = NULL,
                                      @ETLBatchStatusId                                  INT
AS
    MERGE [ctl].ETLBatch AS Target
    USING (SELECT
             @ETLBatchId
             ,@SSISEnvironmentName
             ,@SQLAgentJobName
             --,@Periodicity
             ,@ETLPackageSetId
             ,@StartDateTime
             ,@EndDateTime
             ,@TotalEntryPointPackageCount
             ,@TotalRemainingEntryPointPackageCount
             ,@TotalETLPackageCount
             ,@TotalRemainingETLPackageCount
             ,@CriticalPathPostTransformRemainingETLPackageCount
             ,@CriticalPathPostLoadRemainingETLPackageCount
             ,@ETLBatchStatusId
          ) AS source (ETLBatchId, SSISEnvironmentName, SQLAgentJobName, ETLPackageSetId, StartDateTime, EndDateTime, TotalEntryPointPackageCount, TotalRemainingEntryPointPackageCount, TotalETLPackageCount, TotalRemainingETLPackageCount, CriticalPathPostTransformRemainingETLPackageCount, CriticalPathPostLoadRemainingETLPackageCount, ETLBatchStatusId
          )
    ON target.ETLBatchId = source.ETLBatchId
    WHEN Matched THEN
      UPDATE SET SSISEnvironmentName = ISNULL(source.SSISEnvironmentName, target.SSISEnvironmentName)
                 ,SQLAgentJobName = ISNULL(source.SQLAgentJobName, target.SQLAgentJobName)
                 --,Periodicity = ISNULL(source.Periodicity, target.Periodicity)
                 ,ETLPackageSetId = ISNULL(source.ETLPackageSetId, target.ETLPackageSetId)
                 ,EndDateTime = ISNULL(source.EndDateTime, target.EndDateTime)
                 ,TotalEntryPointPackageCount = ISNULL(source.TotalEntryPointPackageCount, target.TotalEntryPointPackageCount)
                 ,TotalRemainingEntryPointPackageCount = ISNULL(source.TotalRemainingEntryPointPackageCount, target.TotalRemainingEntryPointPackageCount)
                 ,TotalETLPackageCount = ISNULL(source.TotalETLPackageCount, target.TotalETLPackageCount)
                 ,TotalRemainingETLPackageCount = ISNULL(source.TotalRemainingETLPackageCount, target.TotalRemainingETLPackageCount)
                 ,[CriticalPathPostTransformRemainingETLPackageCount] = ISNULL(source.CriticalPathPostTransformRemainingETLPackageCount, target.[CriticalPathPostTransformRemainingETLPackageCount])
                 ,[CriticalPathPostLoadRemainingETLPackageCount] = ISNULL(source.CriticalPathPostLoadRemainingETLPackageCount, target.[CriticalPathPostLoadRemainingETLPackageCount])
                 ,ETLBatchStatusId = ISNULL(source.ETLBatchStatusId, target.ETLBatchStatusId)
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (SSISEnvironmentName
              ,SQLAgentJobName
              --,Periodicity
              ,ETLPackageSetId
              ,StartDateTime
              ,EndDateTime
              ,TotalEntryPointPackageCount
              ,TotalRemainingEntryPointPackageCount
              ,TotalETLPackageCount
              ,TotalRemainingETLPackageCount
              ,[CriticalPathPostTransformRemainingETLPackageCount]
              ,[CriticalPathPostLoadRemainingETLPackageCount]
              ,ETLBatchStatusId
    )
      VALUES(source.SSISEnvironmentName
             ,source.SQLAgentJobName
             --,source.Periodicity
             ,source.ETLPackageSetId
             ,source.StartDateTime
             ,source.EndDateTime
             ,source.TotalEntryPointPackageCount
             ,source.TotalRemainingEntryPointPackageCount
             ,source.TotalETLPackageCount
             ,source.TotalRemainingETLPackageCount
             ,source.CriticalPathPostTransformRemainingETLPackageCount
             ,source.CriticalPathPostLoadRemainingETLPackageCount
             ,1 --Created/Ready: Always set to ready on insert.
    );

    SET @ETLBatchId = ISNULL(@ETLBatchId, SCOPE_IDENTITY())

    RETURN 0 
