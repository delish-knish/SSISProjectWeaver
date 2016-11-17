CREATE VIEW [rpt].[ETLBatchPhaseExecutions]
AS
  SELECT TOP 1000000
    ebsdbe.ETLBatchExecutionId
   ,ebp.ETLBatchPhaseId
   ,ebp.ETLBatchPhase
   ,COUNT(DISTINCT epe.[ETLPackageId])                             AS PackagesExecutedNo
   ,MIN(epe.StartDateTime)                                         AS PhaseStartDateTime
   ,MAX(epe.EndDateTime)                                           AS PhaseEndDateTime
   ,DATEDIFF(MINUTE, MIN(epe.StartDateTime), MAX(epe.EndDateTime)) AS PhaseExecutionDurationInMinutes
  FROM
    [log].[ETLPackageExecution] epe
    JOIN [ctl].[ETLBatchSSISDBExecutions] ebsdbe
      ON epe.SSISDBExecutionId = ebsdbe.SSISDBExecutionId
    JOIN [ctl].[ETLBatch_ETLBatchPhase] b
      ON epe.ETLBatchId = b.ETLBatchId
    JOIN [ctl].[ETLBatchPhase] ebp
      ON b.ETLBatchPhaseId = ebp.ETLBatchPhaseId
    JOIN [ctl].[ETLBatchPhase_ETLPackage] b2
      ON ebp.ETLBatchPhaseId = b2.ETLBatchPhaseId
         AND epe.ETLPackageId = b2.ETLPackageId
  GROUP  BY
    ebsdbe.ETLBatchExecutionId
    ,ebp.ETLBatchPhaseId
    ,ebp.ETLBatchPhase
    ,b.PhaseExecutionOrderNo
  ORDER  BY
    ebsdbe.ETLBatchExecutionId DESC
    ,b.PhaseExecutionOrderNo 
