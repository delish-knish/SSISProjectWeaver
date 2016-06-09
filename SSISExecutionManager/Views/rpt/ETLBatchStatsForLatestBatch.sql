CREATE VIEW [rpt].[ETLBatchStatsForLatestBatch]
AS
  SELECT
    --eb.Periodicity,
    'ETL Batch Id'                     AS Stat
    ,CAST(eb.ETLBatchId AS VARCHAR(50)) AS Value
  FROM
    ctl.ETLBatch eb
    JOIN [dbo].[func_GetLatestETLBatch] (1) leb
      ON eb.ETLBatchId = leb.ETLBatchId
  UNION ALL
  SELECT
    --eb.Periodicity,
    'SQL Agent Job Name'
    ,eb.SQLAgentJobName
  FROM
    ctl.ETLBatch eb
    JOIN [dbo].[func_GetLatestETLBatch] (1) leb
      ON eb.ETLBatchId = leb.ETLBatchId
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Day of Week'
    ,CAST(eb.DayOfWeekName AS VARCHAR(50))
  FROM
    ctl.ETLBatch eb
    JOIN [dbo].[func_GetLatestETLBatch] (1) leb
      ON eb.ETLBatchId = leb.ETLBatchId
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Execution Duration (minutes)'
    ,CAST(ISNULL(eb.ExecutionDurationInMinutes, DATEDIFF(minute, eb.StartDateTime, GETDATE())) AS VARCHAR(19))
  FROM
    ctl.ETLBatch eb
    JOIN [dbo].[func_GetLatestETLBatch] (1) leb
      ON eb.ETLBatchId = leb.ETLBatchId
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Start Time'
    ,CAST(eb.StartDateTime AS VARCHAR(50))
  FROM
    ctl.ETLBatch eb
    JOIN [dbo].[func_GetLatestETLBatch] (1) leb
      ON eb.ETLBatchId = leb.ETLBatchId
  UNION ALL
  SELECT
    --eb.Periodicity,
    'End Time'
    ,CAST(eb.EndDateTime AS VARCHAR(50))
  FROM
    ctl.ETLBatch eb
    JOIN [dbo].[func_GetLatestETLBatch] (1) leb
      ON eb.ETLBatchId = leb.ETLBatchId
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Batch Status'
    ,CAST(ebs.ETLBatchStatus AS VARCHAR(50))
  FROM
    ctl.ETLBatch eb
    JOIN [dbo].[func_GetLatestETLBatch] (1) leb
      ON eb.ETLBatchId = leb.ETLBatchId
    JOIN ref.ETLBatchStatus ebs
      ON eb.ETLBatchStatusId = ebs.ETLBatchStatusId
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Total Package Count'
    ,CAST(eb.TotalETLPackageCount AS VARCHAR(50))
  FROM
    ctl.ETLBatch eb
    JOIN [dbo].[func_GetLatestETLBatch] (1) leb
      ON eb.ETLBatchId = leb.ETLBatchId
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Total Remaining Package Count'
    ,CAST(eb.TotalRemainingETLPackageCount AS VARCHAR(50))
  FROM
    ctl.ETLBatch eb
    JOIN [dbo].[func_GetLatestETLBatch] (1) leb
      ON eb.ETLBatchId = leb.ETLBatchId
  UNION ALL
  SELECT
    --eb.Periodicity,
    'Total Error Count'
    ,CAST(COUNT(1) AS VARCHAR(50))
  FROM
    log.ETLPackageExecutionError pee
    JOIN [dbo].[func_GetLatestETLBatch] (1) leb
      ON pee.ETLBatchId = leb.ETLBatchId
    JOIN ctl.ETLBatch eb
      ON pee.ETLBatchId = eb.ETLBatchId
  GROUP  BY
    pee.ETLBatchId
    --eb.Periodicity
     
