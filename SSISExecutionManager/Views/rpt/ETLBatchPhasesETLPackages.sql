CREATE VIEW [rpt].[ETLBatchPhasesETLPackages]
AS
  SELECT
    b.[ETLBatchPhaseId]
	,ebp.ETLBatchPhase
	,b.ETLPackageId
    ,ep.SSISDBPackageName
  FROM
    [ctl].[ETLBatchPhase_ETLPackage] b
    JOIN ctl.[ETLBatchPhase] ebp
      ON b.[ETLBatchPhaseId] = ebp.[ETLBatchPhaseId] 
	JOIN ctl.ETLPackage ep
	  ON b.ETLPackageId = ep.ETLPackageId

