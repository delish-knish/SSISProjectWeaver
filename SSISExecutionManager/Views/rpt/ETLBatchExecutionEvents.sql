CREATE VIEW [rpt].[ETLBatchExecutionEvents]
AS
  SELECT TOP 1000000
    eb.[ETLBatchExecutionId]           AS ETLBatchExecutionId
    ,eb.[CallingJobName]               AS CallingJobName
    ,eps.[ETLBatchName]                AS ETLBatchName
    ,p.ETLPackageId                    AS ETLPackageId
    ,p.SSISDBFolderName                AS FolderName
    ,p.SSISDBProjectName               AS ProjectName
    ,p.SSISDBPackageName               AS PackageName
    ,be.[ETLBatchExecutionEventId]     AS ETLBatchExecutionEventId
    ,ebet.[ETLBatchExecutionEventType] AS ETLBatchExecutionEventType
    ,be.EventDateTime                  AS EventDateTime
    ,be.[Description]                  AS [Description]
  FROM
    [log].[ETLBatchExecutionEvent] be
    LEFT JOIN [cfg].ETLPackage p
           ON be.ETLPackageId = p.ETLPackageId
    JOIN ctl.[ETLBatchExecution] eb
      ON be.[ETLBatchExecutionId] = eb.[ETLBatchExecutionId]
    JOIN ref.ETLBatchStatus ebs
      ON eb.ETLBatchStatusId = ebs.ETLBatchStatusId
    JOIN ref.[ETLBatchExecutionEventType] ebet
      ON be.[ETLBatchExecutionEventTypeId] = ebet.[ETLBatchExecutionEventTypeId]
    JOIN [cfg].[ETLBatch] eps
      ON eb.[ETLBatchId] = eps.[ETLBatchId]
  ORDER  BY
    [ETLBatchExecutionEventId] DESC 
