CREATE VIEW [rpt].[ETLPackageGroupDependencies]
AS
  SELECT
    epgd.ETLPackageGroupId           AS ETLPackageGroupId
   ,epg.ETLPackageGroup              AS PackageGroup
   ,epgd.DependedOnETLPackageGroupId AS DependedOnETLPackageGroupId
   ,epgdon.ETLPackageGroup           AS DependedOnPackageGroup
   ,epgd.EnabledInd                  AS EnabledInd
  FROM
    [cfg].[ETLPackageGroup_ETLPackageGroupDependency] epgd
    JOIN [cfg].ETLPackageGroup epg
      ON epgd.ETLPackageGroupId = epg.ETLPackageGroupId
    JOIN [cfg].ETLPackageGroup epgdon
      ON epgdon.ETLPackageGroupId = epgd.DependedOnETLPackageGroupId 
