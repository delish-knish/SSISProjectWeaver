CREATE VIEW [rpt].[ETLPackagesForLatestBatch]
AS
  SELECT TOP 1000
    eb.[ETLBatchExecutionId]
    --,eb.Periodicity
    ,eps.[ETLBatchName]
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
  FROM
    [ctl].[ETLPackage] ep
    --Get the id of the last batch executed for NA and EU
    CROSS JOIN (SELECT
                  [ETLBatchExecutionId]
                  ,[ETLBatchId]
                  --,Periodicity
                  ,ROW_NUMBER()
                     OVER (
                       PARTITION BY [ETLBatchId]
                       ORDER BY StartDateTime DESC) rnk
                FROM
                  [ctl].[ETLBatchExecution] WITH (NOLOCK)
               ) eb
    CROSS APPLY [dbo].[func_GetETLPackagesForBatch] (eb.[ETLBatchExecutionId]) pkg
    JOIN ctl.[ETLBatch] eps
      ON eb.[ETLBatchId] = eps.[ETLBatchId]
    LEFT JOIN ref.ETLPackageExecutionStatus rpes
           ON pkg.ETLPackageExecutionStatusId = rpes.ETLPackageExecutionStatusId
    LEFT JOIN ref.ETLExecutionStatus rees 
           ON pkg.ETLExecutionStatusId = rees.ETLExecutionStatusId
  WHERE
    ep.ETLPackageId = pkg.ETLPackageId
    AND rnk = 1
  ORDER  BY
    [SSISDBProjectName]
    ,ExecutionStartDateTime 
