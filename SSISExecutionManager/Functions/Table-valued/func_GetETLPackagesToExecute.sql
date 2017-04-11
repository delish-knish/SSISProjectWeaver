CREATE FUNCTION [dbo].[func_GetETLPackagesToExecute] (@ETLBatchExecutionId INT)
RETURNS TABLE
AS
    RETURN
      (SELECT
         eb.ETLBatchId
        ,bp.ETLPackageId
        ,ep.SSISDBFolderName
        ,ep.SSISDBProjectName
        ,ep.SSISDBPackageName
        ,bp.DependenciesNotMetCount
        ,ep.Use32BitDtExecInd
       FROM
         dbo.[func_GetETLPackagesForBatchExecution](@ETLBatchExecutionId) bp
         JOIN [ctl].ETLPackage ep WITH (NOLOCK)
           ON bp.ETLPackageId = ep.ETLPackageId
         JOIN ctl.ETLBatch eb WITH (NOLOCK)
           ON bp.ETLBatchId = eb.ETLBatchId
         JOIN ctl.[ETLBatch_ETLPackageGroup] ebebp WITH (NOLOCK)
           ON eb.ETLBatchId = ebebp.ETLBatchId
         JOIN ctl.[ETLPackageGroup_ETLPackage] ebpep WITH (NOLOCK)
           ON ebebp.[ETLPackageGroupId] = ebpep.[ETLPackageGroupId]
              AND ep.ETLPackageId = ebpep.ETLPackageId
       WHERE
        (ep.EntryPointPackageInd = 1
          OR ep.BypassEntryPointInd = 1)
        AND ep.ReadyForExecutionInd = 1
        AND (bp.DependenciesNotMetCount = 0
              OR ep.IgnoreDependenciesInd = 1) --All dependencies met or we are going to ignore them
      ) 
