CREATE VIEW [rpt].[ETLPackageExecutions]
AS
  SELECT
    eb.ETLBatchExecutionId
    ,ex.[ETLPackageExecutionId]
    ,ex.[SSISDBExecutionId]
    ,ex.[ETLPackageId]
    ,ex.[ETLBatchId]
    ,eb.[CallingJobName]
    ,ep.SSISDBFolderName
    ,ep.SSISDBProjectName
    ,ep.SSISDBPackageName
    ,ex.[StartDateTime] AS PackageStartDateTime
    ,ex.[EndDateTime]   AS PackageEndDateTime
	,bgb.ETLPackageGroupId
	,bg.ETLPackageGroup
    ,reps.ETLPackageExecutionStatus
    ,ex.[ErrorMessage]
  FROM
    [log].[ETLPackageExecution] ex
    JOIN [ctl].[ETLBatchSSISDBExecutions] dbex
      ON ex.SSISDBExecutionId = dbex.SSISDBExecutionId
    JOIN [ctl].[ETLBatchExecution] eb
      ON dbex.ETLBatchExecutionId = eb.[ETLBatchExecutionId]
    JOIN [cfg].ETLPackage ep
      ON ex.ETLPackageId = ep.ETLPackageId
    JOIN [cfg].[ETLPackageGroup_ETLPackage] b
      ON ep.ETLPackageId = b.ETLPackageId
    JOIN [cfg].[ETLBatch_ETLPackageGroup] bgb
      ON b.ETLPackageGroupId = bgb.ETLPackageGroupId
         AND eb.ETLBatchId = bgb.ETLBatchId
	JOIN [cfg].ETLPackageGroup bg ON bgb.ETLPackageGroupId = bg.ETLPackageGroupId
    JOIN ref.ETLBatchStatus rbs
      ON eb.ETLBatchStatusId = rbs.ETLBatchStatusId
    JOIN ref.ETLPackageExecutionStatus reps
      ON ex.ETLPackageExecutionStatusId = reps.ETLPackageExecutionStatusId 
