CREATE VIEW [rpt].[ETLPackageSetsETLPackages]
AS
  SELECT
    [ETLPackage_ETLPackageSetId]
    ,b.ETLPackageSetId
    ,eps.ETLPackageSetName
    ,b.ETLPackageId
    ,ep.SSISDBPackageName
    ,ep.EnabledInd
  FROM
    [ctl].[ETLPackage_ETLPackageSet] b
    JOIN ctl.ETLPackageSet eps
      ON b.ETLPackageSetId = eps.ETLPackageSetId
    JOIN ctl.ETLPackage ep
      ON b.[ETLPackageId] = ep.[ETLPackageId] 
