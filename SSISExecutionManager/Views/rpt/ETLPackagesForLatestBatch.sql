CREATE VIEW [rpt].[ETLPackagesForLatestBatch]
AS
  SELECT TOP 1000
    eb.ETLBatchId
    --,eb.Periodicity
    ,eps.ETLPackageSetName
    ,ep.[ETLPackageId]
    ,pkg.SSISDBExecutionId
    ,ep.[SSISDBProjectName]
    ,ep.[SSISDBPackageName]
    ,pkg.StartDateTime                                                       AS ExecutionStartDateTime
    ,pkg.EndDateTime                                                         AS ExecutionEndDateTime
    ,DATEDIFF(MINUTE, pkg.StartDateTime, ISNULL(pkg.EndDateTime, GETDATE())) AS ExecutionDurationInMinutes
    ,rpes.ETLPackageExecutionStatus                                          AS PackageExecutionStatus
    ,rees.ETLExecutionStatus                                                 AS SSISParentExecutionStatus
    ,pkg.ETLPackageFirstErrorMessage                                         AS ErrorMessage
    ,pkg.ETLPackageLastMessage
    ,ep.[EntryPointPackageInd]
    ,ep.[ReadyForExecutionInd] --entry point packages only
    ,ep.[ExecutePostTransformInd]
  FROM
    [ctl].[ETLPackage] ep WITH (NOLOCK)
    --Get the id of the last batch executed for NA and EU
    CROSS JOIN (SELECT
                  ETLBatchId
                  ,ETLPackageSetId
                  --,Periodicity
                  ,ROW_NUMBER()
                     OVER (
                       PARTITION BY ETLPackageSetId
                       ORDER BY StartDateTime DESC) rnk
                FROM
                  [ctl].ETLBatch WITH (NOLOCK)
                WHERE
                 ETLPackageSetId IN ( 1, 2 ) --Daily
               ) eb
    CROSS APPLY [dbo].[func_GetETLPackagesForBatch] (eb.ETLBatchId) pkg
    JOIN ctl.ETLPackageSet eps
      ON eb.ETLPackageSetId = eps.ETLPackageSetId
    LEFT JOIN ref.ETLPackageExecutionStatus rpes
           ON pkg.ETLPackageExecutionStatusId = rpes.ETLPackageExecutionStatusId
    LEFT JOIN ref.ETLExecutionStatus rees WITH (NOLOCK)
           ON pkg.ETLExecutionStatusId = rees.ETLExecutionStatusId
  WHERE
    ep.ETLPackageId = pkg.ETLPackageId
    AND rnk = 1
  ORDER  BY
    [SSISDBProjectName]
    ,ExecutionStartDateTime 
