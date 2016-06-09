CREATE VIEW [rpt].[ETLBatches]
AS
  SELECT TOP 10000
    eb.ETLBatchId
    ,eb.SQLAgentJobName
    ,eps.ETLPackageSetName
    --,eb.Periodicity
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
    ,eb.CriticalPathPostTransformRemainingETLPackageCount
    ,eb.CriticalPathPostLoadRemainingETLPackageCount
    ,eb.LastUpdatedDate                                                                                                        AS BatchStatusLastUpdatedDate
  FROM
    ctl.ETLBatch eb
    JOIN ref.ETLBatchStatus rebs
      ON eb.ETLBatchStatusId = rebs.ETLBatchStatusId
    JOIN ctl.ETLPackageSet eps
      ON eb.ETLPackageSetId = eps.ETLPackageSetId
    OUTER APPLY (SELECT TOP 1
                   b.ETLBatchId
                   ,b.StartDateTime
                 FROM
                   ctl.ETLBatch b
                 WHERE
                  eb.SQLAgentJobName = b.SQLAgentJobName
                  --AND eb.Periodicity = b.Periodicity
                  AND eb.ETLPackageSetId = b.ETLPackageSetId
                 ORDER  BY
                  b.StartDateTime DESC) lb
  ORDER  BY
    eb.ETLBatchId DESC 
