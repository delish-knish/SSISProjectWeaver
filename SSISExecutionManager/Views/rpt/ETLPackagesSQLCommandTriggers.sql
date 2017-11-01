CREATE VIEW [rpt].[ETLPackageGroupsETLPackagesSQLCommandConditions]
AS
  SELECT
    b.[ETLPackageGroup_ETLPackage_SQLCommandConditionId]
    ,epgep.ETLPackageGroupId
    ,epgep.ETLPackageId
    ,ep.SSISDBPackageName
    ,b.SQLCommandId
    ,sc.SQLCommandName
    ,sc.SQLCommand
    ,sc.SQLCommandDescription
    ,sc.RequiresETLBatchIdParameterInd
    ,b.EnabledInd
  FROM
    [cfg].[ETLPackageGroup_ETLPackage_SQLCommandCondition] b
    JOIN cfg.ETLPackageGroup_ETLPackage epgep
      ON b.ETLPackageGroup_ETLPackageId = epgep.ETLPackageGroup_ETLPackageId
    JOIN [cfg].SQLCommand sc
      ON b.SQLCommandId = sc.SQLCommandId
    JOIN [cfg].ETLPackage ep
      ON epgep.[ETLPackageId] = ep.[ETLPackageId] 
