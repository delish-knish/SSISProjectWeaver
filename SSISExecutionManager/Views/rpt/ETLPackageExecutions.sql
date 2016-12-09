CREATE VIEW [rpt].[ETLPackageExecutions]
AS
  SELECT
    ex.[ETLPackageExecutionId]
    ,ex.[SSISDBExecutionId]
    ,ex.[ETLPackageId]
    ,ex.[ETLBatchId]
    ,eb.[CallingJobName]
    ,ep.SSISDBProjectName
    ,ep.SSISDBPackageName
    ,ex.[StartDateTime] AS PackageStartDateTime
    ,ex.[EndDateTime]   AS PackageEndDateTime
    ,reps.ETLPackageExecutionStatus
    ,ex.[ErrorMessage]
  FROM
    [log].[ETLPackageExecution] ex
	JOIN [ctl].[ETLBatchSSISDBExecutions] dbex ON ex.SSISDBExecutionId = dbex.SSISDBExecutionId
    JOIN [ctl].[ETLBatchExecution] eb
      ON dbex.ETLBatchExecutionId = eb.[ETLBatchExecutionId]
    JOIN [ctl].ETLPackage ep
      ON ex.ETLPackageId = ep.ETLPackageId
    JOIN ref.ETLBatchStatus rbs
      ON eb.ETLBatchStatusId = rbs.ETLBatchStatusId
    JOIN ref.ETLPackageExecutionStatus reps
      ON ex.ETLPackageExecutionStatusId = reps.ETLPackageExecutionStatusId

