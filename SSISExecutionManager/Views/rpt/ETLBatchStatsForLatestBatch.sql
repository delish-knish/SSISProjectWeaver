CREATE VIEW [rpt].[ETLBatchStatsForLatestBatch]
AS
  SELECT
    --eb.Periodicity,
    'ETL Batch Id'                     AS Stat
    ,CAST(eb.[ETLBatchExecutionId] AS VARCHAR(50)) AS Value
  FROM
    ctl.[ETLBatchExecution] eb
    JOIN [dbo].[func_GetLatestETLBatchExecution] (1) leb
      ON eb.[ETLBatchExecutionId] = leb.[ETLBatchExecutionId]
  UNION ALL
  SELECT
    --eb.Periodicity,
    'SQL Agent Job Name'
    ,eb.[CallingJobName]
  FROM
    ctl.[ETLBatchExecution] eb
    JOIN [dbo].[func_GetLatestETLBatchExecution] (1) leb
      ON eb.[ETLBatchExecutionId] = leb.[ETLBatchExecutionId]
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Day of Week'
    ,CAST(eb.DayOfWeekName AS VARCHAR(50))
  FROM
    ctl.[ETLBatchExecution] eb
    JOIN [dbo].[func_GetLatestETLBatchExecution] (1) leb
      ON eb.[ETLBatchExecutionId] = leb.[ETLBatchExecutionId]
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Execution Duration (minutes)'
    ,CAST(ISNULL(eb.ExecutionDurationInMinutes, DATEDIFF(minute, eb.StartDateTime, GETDATE())) AS VARCHAR(19))
  FROM
    ctl.[ETLBatchExecution] eb
    JOIN [dbo].[func_GetLatestETLBatchExecution] (1) leb
      ON eb.[ETLBatchExecutionId] = leb.[ETLBatchExecutionId]
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Start Time'
    ,CAST(eb.StartDateTime AS VARCHAR(50))
  FROM
    ctl.[ETLBatchExecution] eb
    JOIN [dbo].[func_GetLatestETLBatchExecution] (1) leb
      ON eb.[ETLBatchExecutionId] = leb.[ETLBatchExecutionId]
  UNION ALL
  SELECT
    --eb.Periodicity,
    'End Time'
    ,CAST(eb.EndDateTime AS VARCHAR(50))
  FROM
    ctl.[ETLBatchExecution] eb
    JOIN [dbo].[func_GetLatestETLBatchExecution] (1) leb
      ON eb.[ETLBatchExecutionId] = leb.[ETLBatchExecutionId]
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Batch Status'
    ,CAST(ebs.ETLBatchStatus AS VARCHAR(50))
  FROM
    ctl.[ETLBatchExecution] eb
    JOIN [dbo].[func_GetLatestETLBatchExecution] (1) leb
      ON eb.[ETLBatchExecutionId] = leb.[ETLBatchExecutionId]
    JOIN ref.ETLBatchStatus ebs
      ON eb.ETLBatchStatusId = ebs.ETLBatchStatusId
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Total Package Count'
    ,CAST(eb.TotalETLPackageCount AS VARCHAR(50))
  FROM
    ctl.[ETLBatchExecution] eb
    JOIN [dbo].[func_GetLatestETLBatchExecution] (1) leb
      ON eb.[ETLBatchExecutionId] = leb.[ETLBatchExecutionId]
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Total Remaining Package Count'
    ,CAST(eb.TotalRemainingETLPackageCount AS VARCHAR(50))
  FROM
    ctl.[ETLBatchExecution] eb
    JOIN [dbo].[func_GetLatestETLBatchExecution] (1) leb
      ON eb.[ETLBatchExecutionId] = leb.[ETLBatchExecutionId]
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Total Error Count'
    ,CAST(COUNT(1) AS VARCHAR(50))
  FROM
    log.ETLPackageExecutionError pee
    JOIN [dbo].[func_GetLatestETLBatchExecution] (1) leb
      ON pee.[ETLBatchExecutionId] = leb.[ETLBatchExecutionId]
    JOIN ctl.[ETLBatchExecution] eb
      ON pee.[ETLBatchExecutionId] = eb.[ETLBatchExecutionId]
  GROUP  BY
    pee.[ETLBatchExecutionId]
    --eb.Periodicity
     
