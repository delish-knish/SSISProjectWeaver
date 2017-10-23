CREATE FUNCTION [dbo].[func_GetETLPackagesToExecute] (@ETLBatchExecutionId INT)
RETURNS TABLE
AS
    RETURN
      (SELECT
         eb.ETLBatchId
		,bp.ETLPackageGroupId
        ,bp.ETLPackageId
        ,ep.SSISDBFolderName
        ,ep.SSISDBProjectName
        ,ep.SSISDBPackageName
        ,bp.DependenciesNotMetCount
        ,ep.Use32BitDtExecInd
       FROM
         dbo.[func_GetETLPackagesForBatchExecution](@ETLBatchExecutionId) bp
         JOIN [cfg].ETLPackage ep WITH (NOLOCK)
           ON bp.ETLPackageId = ep.ETLPackageId
         JOIN ctl.ETLBatch eb WITH (NOLOCK)
           ON bp.ETLBatchId = eb.ETLBatchId
         JOIN [cfg].[ETLBatch_ETLPackageGroup] ebebp WITH (NOLOCK)
           ON eb.ETLBatchId = ebebp.ETLBatchId
         JOIN [cfg].[ETLPackageGroup_ETLPackage] ebpep WITH (NOLOCK)
           ON ebebp.[ETLPackageGroupId] = ebpep.[ETLPackageGroupId]
              AND ep.ETLPackageId = ebpep.ETLPackageId
       WHERE
        (ep.EntryPointPackageInd = 1
          OR ebpep.BypassEntryPointInd = 1)
        AND ebpep.ReadyForExecutionInd = 1
        AND (bp.DependenciesNotMetCount = 0
              OR ebpep.IgnoreDependenciesInd = 1) --All dependencies met or we are going to ignore them
      ) 
