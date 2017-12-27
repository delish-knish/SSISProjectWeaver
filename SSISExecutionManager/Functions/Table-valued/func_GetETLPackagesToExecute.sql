CREATE FUNCTION [dbo].[func_GetETLPackagesToExecute] (@ETLBatchExecutionId INT)
RETURNS TABLE
AS
    RETURN
      (SELECT
         eb.ETLBatchId
		,epgep.ETLPackageGroup_ETLPackageId
		,bp.ETLPackageGroupId
        ,bp.ETLPackageId
        ,ep.SSISDBFolderName
        ,ep.SSISDBProjectName
        ,ep.SSISDBPackageName
		,epg.ETLPackageGroup
        ,bp.DependenciesNotMetCount
        ,ep.Use32BitDtExecInd
		,epgep.IgnoreSQLCommandConditionsDefaultInd
       FROM
         dbo.[func_GetETLPackagesForBatchExecution](@ETLBatchExecutionId) bp
         JOIN [cfg].ETLPackage ep 
           ON bp.ETLPackageId = ep.ETLPackageId
         JOIN [cfg].ETLBatch eb 
           ON bp.ETLBatchId = eb.ETLBatchId
         JOIN [cfg].[ETLBatch_ETLPackageGroup] ebebp 
           ON eb.ETLBatchId = ebebp.ETLBatchId
         JOIN [cfg].[ETLPackageGroup_ETLPackage] epgep 
           ON ebebp.[ETLPackageGroupId] = epgep.[ETLPackageGroupId]
              AND ep.ETLPackageId = epgep.ETLPackageId
		 JOIN [cfg].ETLPackageGroup epg ON ebebp.ETLPackageGroupId = epg.ETLPackageGroupId
       WHERE
        (ep.EntryPointPackageInd = 1
          OR epgep.[BypassEntryPointDefaultInd] = 1)
        AND epgep.ReadyForExecutionInd = 1
        AND (bp.DependenciesNotMetCount = 0
              OR epgep.[IgnoreDependenciesDefaultInd] = 1) --All dependencies met or we are going to ignore them
      ) 
