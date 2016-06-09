CREATE PROCEDURE [ctl].[UpdatePackagesToExecuteForBatch] @ETLBatchId INT
AS
    UPDATE [ctl].ETLPackage
    SET    ReadyForExecutionInd = 1
           --,LastUpdatedDate = GETDATE()
           --,LastUpdatedUser = SUSER_SNAME()
    FROM   [ctl].ETLPackage
           JOIN dbo.func_GetETLPackagesForBatch(@ETLBatchId) pkg
             ON [ctl].ETLPackage.ETLPackageId = pkg.ETLPackageId
    WHERE
      EntryPointPackageInd = 1
       OR BypassEntryPointInd = 1

    RETURN 0 
