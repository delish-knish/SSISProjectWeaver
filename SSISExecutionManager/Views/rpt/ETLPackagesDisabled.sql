CREATE VIEW [rpt].[ETLPackagesDisabled]
AS
  SELECT
    ep.[ETLPackageId]
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
  WHERE
    ep.EnabledInd = 0 
	