CREATE VIEW [rpt].[ETLPackageExecutionErrors]
AS
  SELECT TOP 1000
    eb.ETLBatchId                    AS [ETLBatchId]
    ,eb.SQLAgentJobName              AS [SQLAgentJobName]
    --,eb.Periodicity                  AS [Periodicity]
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
    JOIN ctl.ETLPackage p
      ON eper.ETLPackageId = p.ETLPackageId
    JOIN ctl.ETLBatch eb
      ON eper.ETLBatchId = eb.ETLBatchId
    JOIN ref.ETLPackageExecutionErrorType et
      ON eper.[ETLPackageExecutionErrorTypeId] = et.[ETLPackageExecutionErrorTypeId]
  ORDER  BY
    [ETLPackageExecutionErrorId] DESC 
    