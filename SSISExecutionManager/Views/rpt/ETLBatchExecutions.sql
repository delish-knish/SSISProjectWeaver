CREATE VIEW [rpt].[ETLBatchExecutions]
AS
  SELECT TOP 10000
    eb.[ETLBatchExecutionId]
    ,eb.SQLAgentJobName
    ,eps.[ETLBatchName]
    --,eb.Periodicity
    ,eb.DayOfWeekName
    ,eb.StartDateTime
    ,eb.EndDateTime
    ,IIF(eb.EndDateTime IS NULL
         AND lb.StartDateTime > eb.StartDateTime, NULL, DATEDIFF(MINUTE, eb.StartDateTime, ISNULL(eb.EndDateTime, GETDATE()))) AS [ExecutionDurationInMinutes]
    ,IIF(eb.EndDateTime IS NULL
         AND lb.StartDateTime > eb.StartDateTime, 'Cancelled', rebs.ETLBatchStatus)                                            AS ETLBatchStatus
    ,ebp.ETLBatchPhase
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
	LEFT JOIN ctl.ETLBatchPhase ebp 
	  ON eb.ETLBatchPhaseId = ebp.ETLBatchPhaseId
    OUTER APPLY (SELECT TOP 1
                   b.[ETLBatchExecutionId]
                   ,b.StartDateTime
                 FROM
                   ctl.[ETLBatchExecution] b
                 WHERE
                  eb.SQLAgentJobName = b.SQLAgentJobName
                  --AND eb.Periodicity = b.Periodicity
                  AND eb.[ETLBatchId] = b.[ETLBatchId]
                 ORDER  BY
                  b.StartDateTime DESC) lb
  ORDER  BY
    eb.[ETLBatchExecutionId] DESC 
