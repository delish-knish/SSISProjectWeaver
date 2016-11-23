CREATE FUNCTION [dbo].[func_GetMinIncompleteBatchExecutionPhase] (@ETLBatchExecutionId INT)
RETURNS TABLE
AS
RETURN(
	SELECT TOP 1
		ebp.ETLBatchPhaseId
		,ebebp.PhaseExecutionOrderNo
	FROM 
		[dbo].[func_GetETLPackagesForBatchExecution] (@ETLBatchExecutionId) pkg
		JOIN ctl.ETLBatch eb WITH (NOLOCK)
		  ON pkg.ETLBatchId = eb.ETLBatchId
		JOIN ctl.ETLBatch_ETLBatchPhase ebebp WITH (NOLOCK)
		  ON eb.ETLBatchId = ebebp.ETLBatchId
		JOIN ctl.ETLBatchPhase ebp WITH (NOLOCK)
		  ON ebebp.ETLBatchPhaseId = ebp.ETLBatchPhaseId
		JOIN ctl.ETLBatchPhase_ETLPackage ebpep WITH (NOLOCK)
		  ON ebp.ETLBatchPhaseId = ebpep.ETLBatchPhaseId and ebpep.ETLPackageId = pkg.ETLPackageId
	GROUP BY 
		ebp.ETLBatchPhaseId
		,ebebp.PhaseExecutionOrderNo
	HAVING
		SUM(ETLPackageExecutionStatusId) > 0
	ORDER BY 
		ebebp.PhaseExecutionOrderNo ASC)