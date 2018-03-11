CREATE VIEW [rpt].[ETLPackages]
AS
  SELECT
    ep.[ETLPackageId]
    ,ep.[SSISDBFolderName]
    ,ep.[SSISDBProjectName]
    ,ep.[SSISDBPackageName]
    ,ep.[EntryPointPackageInd]
    ,ep.[EntryPointETLPackageId]
	,epep.SSISDBPackageName AS EntryPointPackageName
    ,ep.[HasParamETLBatchExecutionId]
    ,ep.[Use32BitDtExecInd]
    ,ep.[Comments]
    ,ped.AverageExecutionDurationInMinutes
    ,ped.FirstExecutionDate
    ,ped.LastExecutionDate
    ,ISNULL(err.ErrorCount, 0)         AS TotalErrorsLoggedCount
    ,ISNULL(pd.DependencyCount, 0)     AS PackageDependencyCount
    ,ISNULL(pdo.DependedOnCount, 0)    AS PackageDependedOnCount
    ,ISNULL(pg.GroupInstancesCount, 0) AS PackageGroupInstancesCount
  FROM
    [cfg].[ETLPackage] ep
	LEFT JOIN [cfg].[ETLPackage] epep ON ep.EntryPointETLPackageId = epep.ETLPackageId
    LEFT JOIN (SELECT
            ETLPackageId
            ,AVG(ExecutionDurationInMinutes) AS AverageExecutionDurationInMinutes
            ,MIN(StartDateTime)              AS FirstExecutionDate
            ,MAX(StartDateTime)              AS LastExecutionDate
          FROM
            [log].ETLPackageExecutionHistory
          WHERE
           ETLPackageExecutionStatusId = 0
          GROUP  BY
           ETLPackageId) ped
      ON ep.ETLPackageId = ped.ETLPackageId
    LEFT JOIN (SELECT
                 ETLPackageId
                 ,COUNT(*) AS ErrorCount
               FROM
                 [log].ETLPackageExecutionError
               GROUP  BY
                ETLPackageId) err
           ON ep.ETLPackageId = err.ETLPackageId
    LEFT JOIN (SELECT
                 ETLPackageId
                 ,COUNT(*) AS DependencyCount
               FROM
                 cfg.ETLPackage_ETLPackageDependency
               GROUP  BY
                ETLPackageId) pd
           ON ep.ETLPackageId = pd.ETLPackageId
    LEFT JOIN (SELECT
                 DependedOnETLPackageId
                 ,COUNT(*) AS DependedOnCount
               FROM
                 cfg.ETLPackage_ETLPackageDependency
               GROUP  BY
                DependedOnETLPackageId) pdo
           ON ep.ETLPackageId = pdo.DependedOnETLPackageId
    LEFT JOIN (SELECT
                 ETLPackageId
                 ,COUNT(*) AS GroupInstancesCount
               FROM
                 cfg.ETLPackageGroup_ETLPackage
               GROUP  BY
                ETLPackageId) pg
           ON ep.ETLPackageId = pg.ETLPackageId 
