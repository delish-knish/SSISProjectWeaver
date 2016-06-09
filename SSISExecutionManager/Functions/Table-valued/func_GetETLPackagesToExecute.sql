CREATE FUNCTION [dbo].[func_GetETLPackagesToExecute] (@ETLBatchId INT)
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
         dbo.func_GetETLPackagesForBatch(@ETLBatchId) bp
         JOIN [ctl].ETLPackage ep
           ON bp.ETLPackageId = ep.ETLPackageId
         JOIN [ctl].ETLBatch eb
           ON @ETLBatchId = eb.ETLBatchId
       WHERE
        ( ep.EntryPointPackageInd = 1
           OR ep.BypassEntryPointInd = 1 )
        AND ep.ReadyForExecutionInd = 1
        AND ( bp.DependenciesNotMetCount = 0
               OR ep.IgnoreDependenciesInd = 1 ) --All dependencies met or we are going to ignore them
        AND ( ep.[ExecutePostTransformInd] = IIF(ISNULL(eb.[CriticalPathPostTransformRemainingETLPackageCount], 0) = 0, 1, 0) --LOAD packages can be included 
               OR ep.[ExecutePostTransformInd] = 0 )) 
