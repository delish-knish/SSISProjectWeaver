CREATE VIEW [rpt].[ETLBatchEvents]
AS
  SELECT TOP 1000000
    eb.ETLBatchId           AS ETLBatchId
    ,eb.SQLAgentJobName     AS SQLAgentJobName
    --,eb.Periodicity              AS Periodicity
    ,eps.ETLPackageSetName
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
    JOIN ctl.ETLBatch eb
      ON be.ETLBatchId = eb.ETLBatchId
    JOIN ref.ETLBatchStatus ebs
      ON eb.ETLBatchStatusId = ebs.ETLBatchStatusId
    JOIN ref.ETLBatchEventType ebet
      ON be.ETLBatchEventTypeId = ebet.ETLBatchEventTypeId
    JOIN ctl.ETLPackageSet eps
      ON eb.ETLPackageSetId = eps.ETLPackageSetId
  ORDER  BY
    ETLBatchEventId DESC 
