CREATE VIEW [rpt].[ETLPackageGroupETLPackages]
AS
  SELECT
    b.[ETLPackageGroupId]
    ,ebp.[ETLPackageGroup]
    ,b.ETLPackageId
    ,ep.SSISDBPackageName
    ,b.[IgnoreForBatchCompleteInd]
    ,b.[EnabledInd]
    ,b.[ReadyForExecutionInd]
    ,b.[BypassEntryPointInd]
    ,b.[IgnoreDependenciesInd]
    ,b.[MaximumRetryAttempts]
    ,b.[RemainingRetryAttempts]
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
