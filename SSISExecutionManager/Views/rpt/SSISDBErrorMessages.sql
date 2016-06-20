CREATE VIEW [rpt].[SSISDBErrorMessages]
AS
  SELECT TOP 1000
    dwx.[ETLBatchExecutionId]           AS ETLBatchId
    ,eb.SQLAgentJobName      AS SQLAgentJobName
    --,eb.Periodicity          AS Periodicity
    ,p.ETLPackageId          AS ETLPackageId
    ,x.folder_name           AS FolderName
    ,x.project_name          AS ProjectName
    ,x.package_name          AS PackageName
    ,m.[event_message_id]    AS SSISDBEventMessageId
    ,m.[operation_id]        AS SSISDBExecutionId
    ,m.[message_time]        AS ErrorDateTime
    ,m.[message]             AS ErrorMessage
    ,m.[message_source_name] AS ErrorSourceName
    ,m.[message_source_id]   AS ErrorSourceId
    ,m.[subcomponent_name]   AS ErrorSourceSubcomponentName
    ,m.[package_path]        AS PackagePath
    ,m.[execution_path]      AS ExecutionPath
    ,m.[message_code]        AS MessageCode
  FROM
    [$(SSISDB)].[catalog].[event_messages] m
    JOIN [$(SSISDB)].[catalog].[executions] x
      ON m.operation_id = x.execution_id
    JOIN ctl.ETLPackage p
      ON x.folder_name = p.SSISDBFolderName
         AND x.project_name = p.SSISDBProjectName
         AND x.package_name = p.SSISDBPackageName
    JOIN ctl.ETLBatchSSISDBExecutions dwx
      ON x.execution_id = dwx.SSISDBExecutionId
    JOIN ctl.[ETLBatchExecution] eb
      ON dwx.[ETLBatchExecutionId] = eb.[ETLBatchExecutionId]
  WHERE
    message_type = 120
  ORDER  BY
    [event_message_id]DESC 
