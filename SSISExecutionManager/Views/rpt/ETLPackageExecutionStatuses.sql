CREATE VIEW [rpt].[ETLPackageExecutionStatuses]
AS
  SELECT TOP 10000
    ebe.[ETLBatchExecutionId]
    ,eps.[ETLBatchName]
	,pkg.PhaseExecutionOrderNo
    ,ep.[ETLPackageId]
    ,pkg.SSISDBExecutionId
    ,ep.[SSISDBProjectName]
    ,ep.[SSISDBPackageName]
    ,pkg.StartDateTime                                                       AS ExecutionStartDateTime
    ,pkg.EndDateTime                                                         AS ExecutionEndDateTime
    ,DATEDIFF(MINUTE, pkg.StartDateTime, ISNULL(pkg.EndDateTime, GETDATE())) AS ExecutionDurationInMinutes
    ,rpes.ETLPackageExecutionStatus                                          AS PackageExecutionStatus
    ,rees.ETLExecutionStatus                                                 AS SSISParentExecutionStatus
    --,pkg.ETLPackageFirstErrorMessage                                         AS ErrorMessage
    --,pkg.ETLPackageLastMessage
    ,ep.[EntryPointPackageInd]
    ,ep.[ReadyForExecutionInd] --entry point packages only
  FROM
    ctl.[ETLBatchExecution] ebe
    CROSS APPLY [dbo].[func_GetETLPackagesForBatchExecution] (ebe.[ETLBatchExecutionId]) pkg
	JOIN ctl.[ETLPackage] ep ON pkg.ETLPackageId = ep.ETLPackageId
    JOIN ctl.[ETLBatch] eps
      ON ebe.[ETLBatchId] = eps.[ETLBatchId]
    LEFT JOIN ref.ETLPackageExecutionStatus rpes
           ON pkg.ETLPackageExecutionStatusId = rpes.ETLPackageExecutionStatusId
    LEFT JOIN ref.ETLExecutionStatus rees 
           ON pkg.ETLExecutionStatusId = rees.ETLExecutionStatusId
  ORDER  BY
	pkg.PhaseExecutionOrderNo
    ,ep.[SSISDBProjectName]
    ,pkg.StartDateTime
