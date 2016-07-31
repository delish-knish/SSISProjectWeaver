CREATE FUNCTION [dbo].[func_GetETLBatchExecutionStatus] (@ETLBatchExecutionId INT)
RETURNS TABLE
AS
    RETURN
      (SELECT
         IncompletePackageCount = COUNT(*) - SUM(IIF(epb.ETLPackageExecutionStatusId IN ( 0, 2 ), 1, 0))
         ,TotalETLPackageCount = COUNT(*)
         ,TotalRemainingETLPackageCount = COUNT(*) - SUM(IIF(epb.ETLPackageExecutionStatusId IN ( 0, 2 ), 1, 0))
         ,TotalEntryPointPackageCount = SUM(CAST(ep.EntryPointPackageInd AS TINYINT))
         ,TotalRemainingEntryPointPackageCount = SUM(CAST(ep.EntryPointPackageInd AS TINYINT)) - SUM(IIF(epb.ETLPackageExecutionStatusId IN ( 0, 2 )
                                                                                                         AND ep.EntryPointPackageInd = 1, 1, 0))
         ,PackagesReadyToExecuteCount = SUM(CAST(ep.ReadyForExecutionInd AS TINYINT))
         ,ETLBatchExecutionStatusId = CASE
                               WHEN SUM(CAST(ep.EntryPointPackageInd AS TINYINT)) - SUM(IIF(epb.ETLPackageExecutionStatusId IN ( 0, 2 )
                                                                                            AND ep.EntryPointPackageInd = 1, 1, 0)) = 0 THEN 5 --Completed (we use entry point packages to determine completeness because it is possible to have acceptable child package failures)
                               WHEN COUNT(*) - SUM(IIF(epb.ETLPackageExecutionStatusId IN ( 0, 2 ), 1, 0)) > 0
                                    AND SUM(CAST(ep.ReadyForExecutionInd AS TINYINT)) = 0 THEN 4 --Halted
							   WHEN COUNT(*) - SUM(IIF(epb.ETLPackageExecutionStatusId IN ( 0, 2 ), 1, 0)) > 0 THEN 6
                             END
       FROM
         [dbo].[func_GetETLPackagesForBatchExecution] (@ETLBatchExecutionId) epb
         JOIN ctl.[ETLBatchExecution] eb
           ON @ETLBatchExecutionId = eb.[ETLBatchExecutionId]
         JOIN [ctl].ETLPackage ep
           ON epb.ETLPackageId = ep.ETLPackageId) 
