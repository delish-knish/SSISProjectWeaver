CREATE PROCEDURE [ctl].[UpdatePackagesToExecuteForBatch] @ETLBatchExecutionId INT
AS
    UPDATE [ctl].ETLPackage
    SET    ReadyForExecutionInd = 1
          ,RemainingRetryAttempts = MaximumRetryAttempts
    FROM   [ctl].ETLPackage
           JOIN dbo.[func_GetETLPackagesForBatchExecution](@ETLBatchExecutionId) pkg
             ON [ctl].ETLPackage.ETLPackageId = pkg.ETLPackageId
    WHERE
      EntryPointPackageInd = 1
       OR BypassEntryPointInd = 1

	OPTION (FORCE ORDER);

    RETURN 0 
