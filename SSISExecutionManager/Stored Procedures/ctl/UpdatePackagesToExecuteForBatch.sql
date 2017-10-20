CREATE PROCEDURE [ctl].[UpdatePackagesToExecuteForBatch] @ETLBatchExecutionId INT
AS
    UPDATE epgep
    SET    ReadyForExecutionInd = 1
          ,RemainingRetryAttempts = MaximumRetryAttempts
    FROM   dbo.[func_GetETLPackagesForBatchExecution](@ETLBatchExecutionId) pkg 
           JOIN [ctl].ETLPackageGroup_ETLPackage epgep
             ON pkg.ETLPackageId = epgep.ETLPackageId 
		  JOIN [ctl].ETLPackage ep ON epgep.ETLPackageId = ep.ETLPackageId
    WHERE
      ep.EntryPointPackageInd = 1
       OR epgep.BypassEntryPointInd = 1

    RETURN 0 
