CREATE VIEW [rpt].[ETLPackagesDisabled]
AS
  SELECT
    ebpgb.ETLBatchId
	,ep.[ETLPackageId]
    ,ep.[SSISDBFolderName]
    ,ep.[SSISDBProjectName]
    ,ep.[SSISDBPackageName]
    ,ep.[EntryPointPackageInd]
    ,epp.SSISDBPackageName AS [EntryPointETLPackageName]
    ,ep.[BypassEntryPointInd]
    ,ep.[IgnoreDependenciesInd]
    ,ep.[SupportSeverityLevelId]
    ,ep.[Comments]
  FROM
    ctl.ETLPackage ep
    LEFT JOIN ctl.ETLPackage epp
      ON ep.EntryPointETLPackageId = epp.ETLPackageId
	JOIN ctl.ETLPackageGroup_ETLPackage epgb ON ep.ETLpackageID = epgb.ETLPackageId
	JOIN ctl.ETLBatch_ETLPackageGroup ebpgb ON epgb.ETLPackageGroupId = ebpgb.ETLPackageGroupId
  WHERE
    ep.EnabledInd = 0 
	OR epgb.EnabledInd = 0
	OR ebpgb.EnabledInd = 0
	