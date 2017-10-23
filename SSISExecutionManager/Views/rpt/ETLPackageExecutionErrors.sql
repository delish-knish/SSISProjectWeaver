CREATE VIEW [rpt].[ETLPackageExecutionErrors]
AS
  SELECT TOP 1000
    eb.[ETLBatchExecutionId]         AS [ETLBatchExecutionId]
    ,eb.[CallingJobName]             AS [CallingJobName]
    ,p.SSISDBProjectName             AS [SSISDBProjectName]
    ,p.SSISDBPackageName             AS [SSISDBPackageName]
    ,[ETLPackageExecutionErrorId]    AS [ETLPackageExecutionErrorId]
    ,[SSISDBExecutionId]             AS [SSISDBExecutionId]
    ,[SSISDBEventMessageId]          AS [SSISDBEventMessageId]
    ,[ErrorDateTime]                 AS [ErrorDateTime]
    ,[ErrorMessage]                  AS [ErrorMessage]
    ,[EmailNotificationSentDateTime] AS [EmailNotificationSentDateTime]
    ,et.ETLPackageExecutionErrorType AS [ETLPackageExecutionErrorType]
    ,[ETLPackageRestartDateTime]     AS [ETLPackageRestartDateTime]
  FROM
    log.ETLPackageExecutionError eper
    JOIN [cfg].ETLPackage p
      ON eper.ETLPackageId = p.ETLPackageId
    JOIN ctl.[ETLBatchExecution] eb
      ON eper.[ETLBatchExecutionId] = eb.[ETLBatchExecutionId]
    JOIN ref.ETLPackageExecutionErrorType et
      ON eper.[ETLPackageExecutionErrorTypeId] = et.[ETLPackageExecutionErrorTypeId]
  ORDER  BY
    [ETLPackageExecutionErrorId] DESC 
