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
    ,ep.[Comments]
  FROM
    ctl.ETLPackage ep
    LEFT JOIN ctl.ETLPackage epp
           ON ep.EntryPointETLPackageId = epp.ETLPackageId
    JOIN ctl.ETLPackageGroup_ETLPackage epgb
      ON ep.ETLPackageId = epgb.ETLPackageId
    JOIN ctl.ETLBatch_ETLPackageGroup ebpgb
      ON epgb.ETLPackageGroupId = ebpgb.ETLPackageGroupId
    JOIN ctl.ETLPackageGroup epg
      ON epgb.ETLPackageGroupId = epg.ETLPackageGroupId
  WHERE
    epgb.EnabledInd = 0
     OR ebpgb.EnabledInd = 0 
