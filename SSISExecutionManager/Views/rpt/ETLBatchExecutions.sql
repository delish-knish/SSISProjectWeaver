CREATE VIEW [rpt].[ETLBatchExecutions]
AS
  SELECT TOP 10000
    eb.[ETLBatchExecutionId]
    ,eb.[CallingJobName]
    ,eps.[ETLBatchName]
    ,eb.DayOfWeekName
    ,eb.StartDateTime
    ,eb.EndDateTime
    ,IIF(eb.EndDateTime IS NULL
         AND lb.StartDateTime > eb.StartDateTime, NULL, DATEDIFF(MINUTE, eb.StartDateTime, ISNULL(eb.EndDateTime, GETDATE()))) AS [ExecutionDurationInMinutes]
    ,IIF(eb.EndDateTime IS NULL
         AND lb.StartDateTime > eb.StartDateTime, 'Cancelled', rebs.ETLBatchStatus)                                            AS ETLBatchStatus
	,eb.TotalEntryPointPackageCount
    ,eb.TotalRemainingEntryPointPackageCount
    ,eb.TotalETLPackageCount
    ,eb.TotalRemainingETLPackageCount
	,eb.LastUpdatedDate                                                                                                        AS BatchStatusLastUpdatedDate
  FROM
    ctl.[ETLBatchExecution] eb
    JOIN ref.ETLBatchStatus rebs
      ON eb.ETLBatchStatusId = rebs.ETLBatchStatusId
    JOIN ctl.[ETLBatch] eps
      ON eb.[ETLBatchId] = eps.[ETLBatchId]
    OUTER APPLY (SELECT TOP 1
                   b.[ETLBatchExecutionId]
                   ,b.StartDateTime
                 FROM
                   ctl.[ETLBatchExecution] b
                 WHERE
                  eb.[CallingJobName] = b.[CallingJobName]
                  AND eb.[ETLBatchId] = b.[ETLBatchId]
                 ORDER  BY
                  b.StartDateTime DESC) lb
  ORDER  BY
    eb.[ETLBatchExecutionId] DESC 
