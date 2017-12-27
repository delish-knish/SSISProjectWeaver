/*
	1) Backup SSISExecutionManager database
	2) Restore SSISExecutionManager database as SSISExecutionManager_v01	*/


--3) Drop tables 
DROP TABLE ctl.ETLBatch_ETLPackage_SQLCommandCondition;
DROP TABLE [log].ETLPackageExecutionError;
DROP TABLE ctl.ETLPackageGroup_ETLPackage;
DROP TABLE ctl.ETLBatchSSISDBExecutions;

--4) Run the database deployment

--5) Re-populate [cfg].[ETLPackageGroup_ETLPackage]
SET IDENTITY_INSERT [cfg].[ETLPackageGroup_ETLPackage] ON;

INSERT INTO [cfg].[ETLPackageGroup_ETLPackage]
            ([ETLPackageGroup_ETLPackageId]
             ,[ETLPackageGroupId]
             ,[ETLPackageId]
             ,[IgnoreForBatchCompleteDefaultInd]
             ,[EnabledInd]
             ,[ReadyForExecutionInd]
             ,[BypassEntryPointDefaultInd]
             ,[IgnoreDependenciesDefaultInd]
             ,[MaximumRetryAttemptsDefault]
             ,[RemainingRetryAttemptsDefault]
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
FROM   SSISExecutionManager_v01.[ctl].[ETLPackageGroup_ETLPackage] pg
       JOIN SSISExecutionManager_v01.[ctl].ETLPackage p
         ON pg.ETLPackageId = p.ETLPackageId

SET IDENTITY_INSERT [cfg].[ETLPackageGroup_ETLPackage] OFF; 

--6) Re-populate [ctl].[ETLBatchSSISDBExecutions]
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
FROM   [SSISExecutionManager_v01].[ctl].[ETLBatchSSISDBExecutions] ex
       JOIN [SSISExecutionManager_v01].[ctl].ETLBatchExecution ebe
         ON ex.ETLBatchExecutionId = ebe.ETLBatchExecutionId
       JOIN [SSISExecutionManager_v01].[ctl].ETLBatch eb
         ON ebe.ETLBatchId = eb.ETLBatchId
       JOIN [SSISExecutionManager_v01].[ctl].ETLBatch_ETLPackageGroup ebepb
         ON eb.ETLBatchId = ebepb.ETLBatchId
       JOIN [SSISExecutionManager_v01].[ctl].[ETLPackageGroup_ETLPackage] epgep
         ON ebepb.ETLPackageGroupId = epgep.ETLPackageGroupId
            AND ex.ETLPackageId = epgep.ETLPackageId

/*7) Repopulate ctl.ETLBatch_ETLPackage_SQLCommandCondition
SET IDENTITY_INSERT cfg.ETLPackageGroup_ETLPackage_SQLCommandCondition ON
INSERT INTO  cfg.ETLPackageGroup_ETLPackage_SQLCommandCondition (
	[ETLPackageGroup_ETLPackage_SQLCommandConditionId]
      ,[ETLPackageGroup_ETLPackageId]
      ,[SQLCommandId]
      ,[EnabledInd]
      ,[NotificationOnConditionMetEnabledInd]
      ,[NotificationOnConditionNotMetEnabledInd]
      ,[NotificationEmailConfigurationCd]
	  ,[CreatedDate]
      ,[CreatedUser]
      ,[LastUpdatedDate]
      ,[LastUpdatedUser])
SELECT 
	[ETLBatch_ETLPackage_SQLCommandConditionId]
      ,[ETLBatchId]
      ,[ETLPackageId]
      ,[SQLCommandId]
      ,[EnabledInd]
      ,[CreatedDate]
      ,[CreatedUser]
      ,[LastUpdatedDate]
      ,[LastUpdatedUser]
FROM SSISExecutionManager_v01.ctl.ETLBatch_ETLPackage_SQLCommandCondition

SET IDENTITY_INSERT cfg.ETLPackageGroup_ETLPackage_SQLCommandCondition OFF */


--8) Repopulate log.ETLPackageExecutionError
SET IDENTITY_INSERT [log].ETLPackageExecutionError ON
INSERT INTO [log].ETLPackageExecutionError (
[ETLPackageExecutionErrorId]
      ,[SSISDBExecutionId]
      ,[SSISDBEventMessageId]
      ,[ETLBatchExecutionId]
      ,[ETLPackageId]
      ,[ETLPackageGroupId]
      ,[ErrorDateTime]
      ,[ErrorMessage]
      ,[EmailNotificationSentDateTime]
      ,[ETLPackageExecutionErrorTypeId]
      ,[ETLPackageRestartDateTime]
      ,[CreatedDate]
      ,[CreatedUser]
      ,[LastUpdatedDate]
      ,[LastUpdatedUser])
SELECT 
	[ETLPackageExecutionErrorId]
      ,[SSISDBExecutionId]
      ,[SSISDBEventMessageId]
      ,[ETLBatchExecutionId]
      ,[ETLPackageId]
	  ,pg.[ETLPackageGroupId]
      ,[ErrorDateTime]
      ,[ErrorMessage]
      ,[EmailNotificationSentDateTime]
      ,[ETLPackageExecutionErrorTypeId]
      ,[ETLPackageRestartDateTime]
      ,[CreatedDate]
      ,[CreatedUser]
      ,[LastUpdatedDate]
      ,[LastUpdatedUser]
FROM SSISExecutionManager_v01.[log].ETLPackageExecutionError e
CROSS APPLY (SELECT TOP 1 [ETLPackageGroupId] FROM SSISExecutionManager_v01.ctl.ETLPackageGroup_ETLPackage b WHERE e.ETLPackageId = b.ETLPackageId) pg
SET IDENTITY_INSERT [log].ETLPackageExecutionError OFF