CREATE VIEW [rpt].[ETLPackagesDisabled]
AS
  SELECT
    ebpgb.ETLBatchId
    ,epg.ETLPackageGroupId
    ,epg.ETLPackageGroup
    ,ep.[ETLPackageId]
    ,ep.[SSISDBFolderName]
    ,ep.[SSISDBProjectName]
    ,ep.[SSISDBPackageName]
    ,ep.[EntryPointPackageInd]
    ,epp.SSISDBPackageName AS [EntryPointETLPackageName]
    ,epgb.[BypassEntryPointInd]
    ,epgb.[IgnoreDependenciesInd]
    ,epgb.[SupportSeverityLevelId]
    ,epgb.[Comments] --use comments at this level as they should be the most accurate
  FROM
    [cfg].ETLPackage ep
    LEFT JOIN [cfg].ETLPackage epp
           ON ep.EntryPointETLPackageId = epp.ETLPackageId
    JOIN [cfg].ETLPackageGroup_ETLPackage epgb
      ON ep.ETLPackageId = epgb.ETLPackageId
    JOIN [cfg].ETLBatch_ETLPackageGroup ebpgb
      ON epgb.ETLPackageGroupId = ebpgb.ETLPackageGroupId
    JOIN [cfg].ETLPackageGroup epg
      ON epgb.ETLPackageGroupId = epg.ETLPackageGroupId
  WHERE
    epgb.EnabledInd = 0
     OR ebpgb.EnabledInd = 0 
