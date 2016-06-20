CREATE PROCEDURE [ctl].[UpdatePackagesToExecuteForBatch] @ETLBatchExecutionId INT
AS
    UPDATE [ctl].ETLPackage
    SET    ReadyForExecutionInd = 1
    FROM   [ctl].ETLPackage
           JOIN dbo.func_GetETLPackagesForBatch(@ETLBatchExecutionId) pkg
             ON [ctl].ETLPackage.ETLPackageId = pkg.ETLPackageId
    WHERE
      EntryPointPackageInd = 1
       OR BypassEntryPointInd = 1

    RETURN 0 
