CREATE VIEW [rpt].[ETLBatchExecutionEvents]
AS
  SELECT TOP 1000000
    eb.[ETLBatchExecutionId]           AS ETLBatchId
    ,eb.SQLAgentJobName     AS SQLAgentJobName
    --,eb.Periodicity              AS Periodicity
    ,eps.[ETLBatchName]
    ,p.ETLPackageId         AS ETLPackageId
    ,p.SSISDBFolderName     AS FolderName
    ,p.SSISDBProjectName    AS ProjectName
    ,p.SSISDBPackageName    AS PackageName
    ,be.ETLBatchEventId     AS ETLBatchEventId
    ,ebet.ETLBatchEventType AS ETLBatchEventType
    ,be.EventDateTime       AS EventDateTime
    ,be.[Description]       AS [Description]
  FROM
    [log].ETLBatchEvent be
    LEFT JOIN ctl.ETLPackage p
           ON be.ETLPackageId = p.ETLPackageId
    JOIN ctl.[ETLBatchExecution] eb
      ON be.[ETLBatchExecutionId] = eb.[ETLBatchExecutionId]
    JOIN ref.ETLBatchStatus ebs
      ON eb.ETLBatchStatusId = ebs.ETLBatchStatusId
    JOIN ref.ETLBatchEventType ebet
      ON be.ETLBatchEventTypeId = ebet.ETLBatchEventTypeId
    JOIN ctl.[ETLBatch] eps
      ON eb.[ETLBatchId] = eps.[ETLBatchId]
  ORDER  BY
    ETLBatchEventId DESC 
