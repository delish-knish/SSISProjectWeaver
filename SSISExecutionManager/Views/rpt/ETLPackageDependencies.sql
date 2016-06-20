CREATE VIEW [rpt].[ETLPackageDependencies]
AS
  SELECT
    epd.ETLPackageId            AS ETLPackageId
    ,ep.SSISDBPackageName       AS PackageName
    ,epd.DependedOnETLPackageId AS DependedOnETLPackageId
    ,epdon.SSISDBPackageName    AS DependedOnPackageName
    ,epd.EnabledInd             AS EnabledInd
  FROM
    [ctl].[ETLPackage_ETLPackageDependency] epd
    JOIN [ctl].ETLPackage ep
      ON epd.ETLPackageId = ep.ETLPackageId
    JOIN [ctl].ETLPackage epdon
      ON epdon.ETLPackageId = epd.DependedOnETLPackageId
