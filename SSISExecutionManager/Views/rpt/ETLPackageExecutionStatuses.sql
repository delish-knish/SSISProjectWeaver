CREATE VIEW [rpt].[ETLPackageExecutionStatuses]
AS
  SELECT ebe.[ETLBatchExecutionId],
                 eps.[ETLBatchName],
                 ep.[ETLPackageId],
                 pkg.SSISDBExecutionId,
				 ep.[SSISDBFolderName],
                 ep.[SSISDBProjectName],
                 ep.[SSISDBPackageName],
                 pkg.StartDateTime                                                       AS ExecutionStartDateTime,
                 pkg.EndDateTime                                                         AS ExecutionEndDateTime,
                 Datediff(MINUTE, pkg.StartDateTime, Isnull(pkg.EndDateTime, Getdate())) AS ExecutionDurationInMinutes,
				 rpes.ETLPackageExecutionStatus                                          AS PackageExecutionStatus,
				 rees.ETLExecutionStatus                                                 AS SSISParentExecutionStatus,
                 ep.[EntryPointPackageInd],
                 ep.[ReadyForExecutionInd] --entry point packages only
FROM   ctl.[ETLBatchExecution] ebe WITH (NOLOCK)
       CROSS APPLY [dbo].[func_GetETLPackagesForBatchExecution] (ebe.[ETLBatchExecutionId]) pkg
       JOIN ctl.[ETLPackage] ep WITH (NOLOCK)
         ON pkg.ETLPackageId = ep.ETLPackageId
       JOIN ctl.[ETLBatch] eps WITH (NOLOCK)
         ON ebe.[ETLBatchId] = eps.[ETLBatchId]
       LEFT JOIN ref.ETLExecutionStatus rees WITH (NOLOCK)
              ON pkg.ETLExecutionStatusId = rees.ETLExecutionStatusId
       LEFT JOIN ref.ETLPackageExecutionStatus rpes WITH (NOLOCK)
              ON pkg.ETLPackageExecutionStatusId = rpes.ETLPackageExecutionStatusId

GO 
