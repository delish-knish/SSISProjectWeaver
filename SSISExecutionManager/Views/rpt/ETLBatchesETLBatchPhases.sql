CREATE VIEW [rpt].[ETLBatchesETLBatchPhases]
AS
  SELECT
    b.[ETLBatch_ETLBatchPhaseId]
    ,b.[ETLBatchId]
    ,eps.[ETLBatchName]
    ,b.[ETLBatchPhaseId]
    ,ep.[ETLBatchPhase]
	,b.[PhaseExecutionOrderNo]
  FROM
    [ctl].[ETLBatch_ETLBatchPhase] b
    JOIN ctl.[ETLBatch] eps
      ON b.[ETLBatchId] = eps.[ETLBatchId]
    JOIN ctl.[ETLBatchPhase] ep
      ON b.[ETLBatchPhaseId] = ep.[ETLBatchPhaseId] 
