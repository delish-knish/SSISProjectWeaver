CREATE PROCEDURE [ctl].[UpdatePackagesToExecuteForBatch] @ETLBatchExecutionId INT
AS
    UPDATE epgep
    SET    ReadyForExecutionInd = 1
          ,[RemainingRetryAttemptsDefault] = [MaximumRetryAttemptsDefault]
    FROM   dbo.[func_GetETLPackagesForBatchExecution](@ETLBatchExecutionId) pkg 
           JOIN [cfg].ETLPackageGroup_ETLPackage epgep
             ON pkg.ETLPackageId = epgep.ETLPackageId 
		  JOIN [cfg].ETLPackage ep ON epgep.ETLPackageId = ep.ETLPackageId
    WHERE
      ep.EntryPointPackageInd = 1
       OR epgep.[BypassEntryPointDefaultInd] = 1

    RETURN 0 
