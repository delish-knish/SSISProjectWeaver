CREATE VIEW [rpt].[ETLPackageGroupDependencies]
AS
  SELECT
    epgd.ETLPackageGroupId           AS ETLPackageGroupId
   ,epg.ETLPackageGroup              AS PackageGroup
   ,epgd.DependedOnETLPackageGroupId AS DependedOnETLPackageGroupId
   ,epgdon.ETLPackageGroup           AS DependedOnPackageGroup
   ,epgd.EnabledInd                  AS EnabledInd
  FROM
    [ctl].[ETLPackageGroup_ETLPackageGroupDependency] epgd
    JOIN [ctl].ETLPackageGroup epg
      ON epgd.ETLPackageGroupId = epg.ETLPackageGroupId
    JOIN [ctl].ETLPackageGroup epgdon
      ON epgdon.ETLPackageGroupId = epgd.DependedOnETLPackageGroupId 
