CREATE FUNCTION [dbo].[func_GetETLBatchStatus] (@ETLBatchId INT)
RETURNS TABLE
AS
    RETURN
      (SELECT
         CriticalPathPostTransformRemainingETLPackageCount = SUM(IIF([InCriticalPathPostTransformProcessesInd] = 1
                                                                     AND epb.ETLPackageExecutionStatusId NOT IN ( 0, 2 ), 1, 0))
         ,CriticalPathPostLoadRemainingETLPackageCount = SUM(IIF([InCriticalPathPostLoadProcessesInd] = 1
                                                                 AND epb.ETLPackageExecutionStatusId NOT IN ( 0, 2 ), 1, 0))
         ,IncompletePackageCount = COUNT(*) - SUM(IIF(epb.ETLPackageExecutionStatusId IN ( 0, 2 ), 1, 0))
         ,TotalETLPackageCount = COUNT(*)
         ,TotalRemainingETLPackageCount = COUNT(*) - SUM(IIF(epb.ETLPackageExecutionStatusId IN ( 0, 2 ), 1, 0))
         ,TotalEntryPointPackageCount = SUM(CAST(ep.EntryPointPackageInd AS TINYINT))
         ,TotalRemainingEntryPointPackageCount = SUM(CAST(ep.EntryPointPackageInd AS TINYINT)) - SUM(IIF(epb.ETLPackageExecutionStatusId IN ( 0, 2 )
                                                                                                         AND ep.EntryPointPackageInd = 1, 1, 0))
         ,PackagesReadyToExecuteCount = SUM(CAST(ep.ReadyForExecutionInd AS TINYINT))
         ,ETLBatchStatusId = CASE
                               WHEN SUM(CAST(ep.EntryPointPackageInd AS TINYINT)) - SUM(IIF(epb.ETLPackageExecutionStatusId IN ( 0, 2 )
                                                                                            AND ep.EntryPointPackageInd = 1, 1, 0)) = 0 THEN 5 --Completed (we use entry point packages to determine completeness because it is possible to have acceptable child package failures such as Alt Hierarchy Extract)
                               WHEN COUNT(*) - SUM(IIF(epb.ETLPackageExecutionStatusId IN ( 0, 2 ), 1, 0)) > 0
                                    AND SUM(CAST(ep.ReadyForExecutionInd AS TINYINT)) = 0 THEN 4 --Halted
							   --If all post transform critical path packages have succeeded and there are any incomplete post-load critical path packages
                               WHEN SUM(IIF([InCriticalPathPostTransformProcessesInd] = 1
                                            AND epb.ETLPackageExecutionStatusId NOT IN ( 0, 2 ), 1, 0)) = 0
                                    AND SUM(IIF([InCriticalPathPostLoadProcessesInd] = 1
                                                AND epb.ETLPackageExecutionStatusId NOT IN ( 0, 2 ), 1, 0)) > 0 THEN 3 --Running post-transform processes
                               WHEN SUM(IIF([InCriticalPathPostTransformProcessesInd] = 1
                                            AND epb.ETLPackageExecutionStatusId NOT IN ( 0, 2 ), 1, 0)) > 0 THEN 2 --Running extract and transform
                             END
       FROM
         [dbo].[func_GetETLPackagesForBatch] (@ETLBatchId) epb
         JOIN ctl.ETLBatch eb
           ON @ETLBatchId = eb.ETLBatchId
         JOIN [ctl].ETLPackage ep
           ON epb.ETLPackageId = ep.ETLPackageId) 
