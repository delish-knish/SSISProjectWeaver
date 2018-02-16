﻿CREATE FUNCTION [dbo].[func_GetETLBatchExecutionStatus] (@ETLBatchExecutionId INT)
RETURNS TABLE
AS
    RETURN
      (SELECT
         IncompletePackageCount = COUNT(*) - SUM(IIF(epb.ETLPackageExecutionStatusId IN (0, 2), 1, 0))
        ,TotalETLPackageCount = COUNT(*)
        ,TotalRemainingETLPackageCount = COUNT(*) - SUM(IIF(epb.ETLPackageExecutionStatusId IN (0, 2), 1, 0))
        ,TotalEntryPointPackageCount = SUM(CAST(ep.EntryPointPackageInd AS TINYINT))
        ,TotalRemainingEntryPointPackageCount = SUM(CAST(ep.EntryPointPackageInd AS TINYINT)) - SUM(IIF(epb.ETLPackageExecutionStatusId IN (0, 2)
                                                                                                         AND ep.EntryPointPackageInd = 1, 1, 0))
        ,PackagesReadyToExecuteCount = SUM(CAST(epb.ReadyForExecutionInd AS TINYINT))
        ,RunningPackageCount = SUM(r.RunningPackageCount)
        ,ETLBatchExecutionStatusId = CASE
                                        WHEN MIN(eb.ETLBatchStatusId) = 10 THEN 10 -- The batch has been manually canceled and we don't want to overwrite that
                                        WHEN SUM(CAST(ep.EntryPointPackageInd AS TINYINT)) - SUM(IIF((epb.ETLPackageExecutionStatusId IN (0, 2) --Succeeded or Completed
                                                                                                      AND ep.EntryPointPackageInd = 1)
                                                                                                      OR (epb.ETLPackageExecutionStatusId IN(1, 4) --Failed or Canceled but can be ignored for batch complete status
                                                                                                          AND ep.EntryPointPackageInd = 1
                                                                                                          AND epb.IgnoreForBatchCompleteInd = 1), 1, 0)) = 0 THEN 5 --Completed (we use entry point packages to determine completeness because it is possible to have acceptable child package failures)
                                        --If total entry point packages for the batch is greater than the total completed entry point packages and nothing is running
                                        WHEN SUM(IIF(ep.EntryPointPackageInd = 1, 1, 0)) - SUM(IIF((epb.ETLPackageExecutionStatusId IN (0, 2)
                                                                                                    AND ep.EntryPointPackageInd = 1), 1, 0)) > 0
                                             AND SUM(CAST([dbo].[func_IsETLPackageRunning] (ep.SSISDBFolderName, ep.SSISDBProjectName, ep.SSISDBPackageName) AS INT)) = 0 THEN 4 --Halted
                                        WHEN COUNT(*) - SUM(IIF(epb.ETLPackageExecutionStatusId IN (0, 2), 1, 0)) > 0 THEN 6
                                      END
       FROM
         [dbo].[func_GetETLPackagesForBatchExecution] (@ETLBatchExecutionId) epb
         JOIN ctl.[ETLBatchExecution] eb WITH (NOLOCK)
           ON @ETLBatchExecutionId = eb.[ETLBatchExecutionId]
         JOIN [cfg].ETLPackage ep WITH (NOLOCK)
           ON epb.ETLPackageId = ep.ETLPackageId
         LEFT JOIN (SELECT
                      execution_id
                     ,1 AS RunningPackageCount
                    FROM
                      [ctl].[ETLBatchSSISDBExecutions] x
                      JOIN [$(SSISDB)].[catalog].executions exc
                        ON x.SSISDBExecutionId = exc.execution_id
                    WHERE
                     ETLBatchExecutionId = @ETLBatchExecutionId
                     AND [status] = 2
                    GROUP  BY
                     execution_id) r
                ON epb.SSISDBExecutionId = r.execution_id) 
