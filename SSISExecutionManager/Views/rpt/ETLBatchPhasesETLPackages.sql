CREATE VIEW [rpt].[ETLPackageGroupETLPackages]
AS
  SELECT
    b.[ETLPackageGroupId]
	,ebp.[ETLPackageGroup]
	,b.ETLPackageId
    ,ep.SSISDBPackageName
  FROM
    [ctl].[ETLPackageGroup_ETLPackage] b
    JOIN ctl.[ETLPackageGroup] ebp
      ON b.[ETLPackageGroupId] = ebp.[ETLPackageGroupId] 
	JOIN ctl.ETLPackage ep
	  ON b.ETLPackageId = ep.ETLPackageId

