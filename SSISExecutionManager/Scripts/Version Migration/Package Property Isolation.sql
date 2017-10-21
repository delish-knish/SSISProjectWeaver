SET IDENTITY_INSERT [ctl].[ETLPackageGroup_ETLPackage] ON;

INSERT INTO [ctl].[ETLPackageGroup_ETLPackage]
            ([ETLPackageGroup_ETLPackageId]
             ,[ETLPackageGroupId]
             ,[ETLPackageId]
             ,[IgnoreForBatchCompleteInd]
             ,[EnabledInd]
             ,[ReadyForExecutionInd]
             ,[BypassEntryPointInd]
             ,[IgnoreDependenciesInd]
             ,[MaximumRetryAttempts]
             ,[RemainingRetryAttempts]
             ,[OverrideSSISDBLoggingLevelId]
             ,[ExecuteSundayInd]
             ,[ExecuteMondayInd]
             ,[ExecuteTuesdayInd]
             ,[ExecuteWednesdayInd]
             ,[ExecuteThursdayInd]
             ,[ExecuteFridayInd]
             ,[ExecuteSaturdayInd]
             ,[SupportSeverityLevelId]
             ,[Comments]
             ,[CreatedDate]
             ,[CreatedUser]
             ,[LastUpdatedDate]
             ,[LastUpdatedUser])
SELECT
  pg.[ETLPackageGroup_ETLPackageId]
  ,pg.[ETLPackageGroupId]
  ,pg.[ETLPackageId]
  ,pg.[IgnoreForBatchCompleteInd]
  ,pg.[EnabledInd]
  ,p.[ReadyForExecutionInd]
  ,p.[BypassEntryPointInd]
  ,p.[IgnoreDependenciesInd]
  ,p.[MaximumRetryAttempts]
  ,p.[RemainingRetryAttempts]
  ,p.[OverrideSSISDBLoggingLevelId]
  ,p.[ExecuteSundayInd]
  ,p.[ExecuteMondayInd]
  ,p.[ExecuteTuesdayInd]
  ,p.[ExecuteWednesdayInd]
  ,p.[ExecuteThursdayInd]
  ,p.[ExecuteFridayInd]
  ,p.[ExecuteSaturdayInd]
  ,p.[SupportSeverityLevelId]
  ,p.[Comments]
  ,pg.[CreatedDate]
  ,pg.[CreatedUser]
  ,pg.[LastUpdatedDate]
  ,pg.[LastUpdatedUser]
FROM   SSISExecutionManager.[ctl].[ETLPackageGroup_ETLPackage] pg
       JOIN SSISExecutionManager.[ctl].ETLPackage p
         ON pg.ETLPackageId = p.ETLPackageId

SET IDENTITY_INSERT [ctl].[ETLPackageGroup_ETLPackage] OFF; 

INSERT INTO [ctl].[ETLBatchSSISDBExecutions]
            ([ETLBatchExecutionId]
             ,[SSISDBExecutionId]
             ,[ETLPackageId]
             ,[ETLPackageGroupId]
             ,[CreatedDate]
             ,[CreatedUser]
             ,[LastUpdatedDate]
             ,[LastUpdatedUser])
SELECT
  ex.[ETLBatchExecutionId]
  ,ex.[SSISDBExecutionId]
  ,ex.[ETLPackageId]
  ,ebepb.[ETLPackageGroupId]
  ,ex.[CreatedDate]
  ,ex.[CreatedUser]
  ,ex.[LastUpdatedDate]
  ,ex.[LastUpdatedUser]
FROM   [SSISExecutionManager].[ctl].[ETLBatchSSISDBExecutions] ex
       JOIN [SSISExecutionManager].[ctl].ETLBatchExecution ebe
         ON ex.ETLBatchExecutionId = ebe.ETLBatchExecutionId
       JOIN [SSISExecutionManager].[ctl].ETLBatch eb
         ON ebe.ETLBatchId = eb.ETLBatchId
       JOIN [SSISExecutionManager].[ctl].ETLBatch_ETLPackageGroup ebepb
         ON eb.ETLBatchId = ebepb.ETLBatchId
       JOIN [ctl].[ETLPackageGroup_ETLPackage] epgep
         ON ebepb.ETLPackageGroupId = epgep.ETLPackageGroupId
            AND ex.ETLPackageId = epgep.ETLPackageId
