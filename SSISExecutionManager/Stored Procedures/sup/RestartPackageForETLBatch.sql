CREATE PROCEDURE [sup].[RestartPackageForETLBatch] @SSISDBFolderName           NVARCHAR(128),
                                                   @SSISDBProjectName          NVARCHAR(128),
                                                   @SSISDBPackageName          NVARCHAR (260),
                                                   @ETLPackageGroupId          INT,
                                                   @BypassEntryPointPackageInd BIT = 0,
                                                   @IgnoreDependenciesInd      BIT = 0
AS
    /*The purpose of this stored procedure is to set the status of a package (via ReadyForExecutionInd) so that it will be picked up again by the currently running ETL batch(es) 
    *It is only used at the package level since only entry-point packages can be restarted, therefore there is no option for a "project" level reset. */

    UPDATE epgep
    SET    ReadyForExecutionInd = 1
           ,[BypassEntryPointDefaultInd] = @BypassEntryPointPackageInd
           ,[IgnoreDependenciesDefaultInd] = @IgnoreDependenciesInd
           ,LastUpdatedDate = GETDATE()
           ,LastUpdatedUser = SUSER_SNAME()
    FROM   [cfg].ETLPackageGroup_ETLPackage epgep
           JOIN [cfg].ETLPackage ep
             ON epgep.ETLPackageId = ep.ETLPackageId
    WHERE
      @SSISDBFolderName = SSISDBFolderName
      AND @SSISDBProjectName = SSISDBProjectName
      AND @SSISDBPackageName = SSISDBPackageName
      AND epgep.ETLPackageGroupId = @ETLPackageGroupId

    IF @@ROWCOUNT = 0
      THROW 50000, 'The package does not exist. No packages were reset.', 1;

    RETURN 0 
