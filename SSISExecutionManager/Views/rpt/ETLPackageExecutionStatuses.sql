CREATE VIEW [rpt].[ETLPackageExecutionStatuses]
AS
  SELECT
    ebe.[ETLBatchExecutionId]
    ,eps.[ETLBatchName]
	,epgep.ETLPackageGroupId
    ,ep.[ETLPackageId]
    ,pkg.SSISDBExecutionId
    ,ep.[SSISDBFolderName]
    ,ep.[SSISDBProjectName]
    ,ep.[SSISDBPackageName]
    ,pkg.StartDateTime                                                       AS ExecutionStartDateTime
    ,pkg.EndDateTime                                                         AS ExecutionEndDateTime
    ,DATEDIFF(MINUTE, pkg.StartDateTime, Isnull(pkg.EndDateTime, GETDATE())) AS ExecutionDurationInMinutes
    ,rpes.ETLPackageExecutionStatus                                          AS PackageExecutionStatus
    ,rees.ETLExecutionStatus                                                 AS SSISParentExecutionStatus
    ,ep.[EntryPointPackageInd]
    ,epgep.[ReadyForExecutionInd] --entry point packages only
  FROM
    ctl.[ETLBatchExecution] ebe WITH (NOLOCK)
    CROSS APPLY [dbo].[func_GetETLPackagesForBatchExecution] (ebe.[ETLBatchExecutionId]) pkg
    JOIN [cfg].ETLPackageGroup_ETLPackage epgep
      ON pkg.ETLPackageId = epgep.ETLPackageId
         AND pkg.ETLPackageGroupId = epgep.ETLPackageGroupId
    JOIN [cfg].[ETLPackage] ep WITH (NOLOCK)
      ON pkg.ETLPackageId = ep.ETLPackageId
    JOIN [cfg].[ETLBatch] eps WITH (NOLOCK)
      ON ebe.[ETLBatchId] = eps.[ETLBatchId]
    LEFT JOIN ref.ETLExecutionStatus rees WITH (NOLOCK)
           ON pkg.ETLExecutionStatusId = rees.ETLExecutionStatusId
    LEFT JOIN ref.ETLPackageExecutionStatus rpes WITH (NOLOCK)
           ON pkg.ETLPackageExecutionStatusId = rpes.ETLPackageExecutionStatusId

GO 
