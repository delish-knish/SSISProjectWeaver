CREATE VIEW [rpt].[ETLPackageGroupETLPackages]
AS
  SELECT
    b.[ETLPackageGroupId]
    ,ebp.[ETLPackageGroup]
    ,b.ETLPackageId
    ,ep.SSISDBPackageName
    ,b.[IgnoreForBatchCompleteDefaultInd]
    ,b.[EnabledInd]
    ,b.[ReadyForExecutionInd]
    ,b.[BypassEntryPointDefaultInd]
    ,b.[IgnoreDependenciesDefaultInd]
    ,b.[MaximumRetryAttemptsDefault]
    ,b.[RemainingRetryAttemptsDefault]
    ,b.[OverrideSSISDBLoggingLevelId]
    ,b.[ExecuteSundayInd]
    ,b.[ExecuteMondayInd]
    ,b.[ExecuteTuesdayInd]
    ,b.[ExecuteWednesdayInd]
    ,b.[ExecuteThursdayInd]
    ,b.[ExecuteFridayInd]
    ,b.[ExecuteSaturdayInd]
    ,b.[SupportSeverityLevelId]
    ,b.[Comments]
  FROM
    [cfg].[ETLPackageGroup_ETLPackage] b
    JOIN [cfg].[ETLPackageGroup] ebp
      ON b.[ETLPackageGroupId] = ebp.[ETLPackageGroupId]
    JOIN [cfg].ETLPackage ep
      ON b.ETLPackageId = ep.ETLPackageId 
