CREATE FUNCTION [dbo].[func_GetETLPackagesToExecute] (@ETLBatchExecutionId INT)
RETURNS TABLE
AS
    RETURN
      (SELECT
         bp.ETLPackageId
         ,ep.SSISDBFolderName
         ,ep.SSISDBProjectName
         ,ep.SSISDBPackageName
         ,bp.DependenciesNotMetCount
         ,ep.Use32BitDtExecInd
       FROM
         dbo.func_GetETLPackagesForBatch(@ETLBatchExecutionId) bp
         JOIN [ctl].ETLPackage ep
           ON bp.ETLPackageId = ep.ETLPackageId
		 JOIN ctl.ETLBatch eb 
		   ON bp.ETLBatchId = eb.ETLBatchId
		 JOIN ctl.ETLBatch_ETLBatchPhase ebebp 
		   ON eb.ETLBatchId = ebebp.ETLBatchId
		 JOIN ctl.ETLBatchPhase_ETLPackage ebpep 
		   ON ebebp.ETLBatchPhaseId = ebpep.ETLBatchPhaseId
				AND ep.ETLPackageId = ebpep.ETLPackageId 
		 CROSS APPLY [dbo].[func_GetMinIncompleteBatchExecutionPhase] (@ETLBatchExecutionId) mp
			
       WHERE
        ( ep.EntryPointPackageInd = 1
           OR ep.BypassEntryPointInd = 1 )
        AND ep.ReadyForExecutionInd = 1
        AND ( bp.DependenciesNotMetCount = 0
               OR ep.IgnoreDependenciesInd = 1 ) --All dependencies met or we are going to ignore them
		AND ebebp.PhaseExecutionOrderNo = mp.ETLBatchPhaseId --get packages from the minimum incomplete phase(s)   	   
		) 
