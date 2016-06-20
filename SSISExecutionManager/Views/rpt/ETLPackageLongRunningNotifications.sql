CREATE VIEW [rpt].[ETLPackageLongRunningNotifications]
AS
  SELECT TOP 1000
    dwx.[ETLBatchExecutionId]                    AS ETLBatchId
    ,eplr.SSISDBExecutionId           AS SSISDBExecutionId
    ,eb.SQLAgentJobName               AS SQLAgentJobName
    --,eb.Periodicity                   AS Periodicity
    ,p.ETLPackageId                   AS ETLPackageId
    ,x.folder_name                    AS FolderName
    ,x.project_name                   AS ProjectName
    ,x.package_name                   AS PackageName
    ,eplr.ExecutionStartTime          AS ExecutionStartTime
    ,eplr.AverageExecutionTimeMinutes AS AverageExecutionTimeMinutes
    ,eplr.CurrentExectionTimeMinutes  AS CurrentExectionTimeMinutes
    ,eplr.CreatedDate                 AS LoggedAndNotifiedDateTime
  FROM
    [log].[ETLPackageExecutionLongRunning] eplr
    JOIN [$(SSISDB)].[catalog].[executions] x
      ON eplr.SSISDBExecutionId = x.execution_id
    LEFT JOIN ctl.ETLPackage p
           ON x.folder_name = p.SSISDBFolderName
              AND x.project_name = p.SSISDBProjectName
              AND x.package_name = p.SSISDBPackageName
    LEFT JOIN ctl.ETLBatchSSISDBExecutions dwx
           ON x.execution_id = dwx.SSISDBExecutionId
    LEFT JOIN ctl.[ETLBatchExecution] eb
           ON dwx.[ETLBatchExecutionId] = eb.[ETLBatchExecutionId]
  ORDER  BY
    eplr.ExecutionStartTime DESC 
