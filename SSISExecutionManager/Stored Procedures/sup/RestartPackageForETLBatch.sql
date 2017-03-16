CREATE PROCEDURE [sup].[RestartPackageForETLBatch] @SSISDBFolderName           NVARCHAR(128),
                                                   @SSISDBProjectName          NVARCHAR(128),
                                                   @SSISDBPackageName          NVARCHAR (260),
                                                   @BypassEntryPointPackageInd BIT = 0,
                                                   @IgnoreDependenciesInd      BIT = 0
AS
    /*The purpose of this stored procedure is to set the status of a package (via ReadyForExecutionInd) so that it will be picked up again by the currently running ETL batch(es) 
	*It is only used at the package level since only entry-point packages can be restarted, therefore there is no option for a "project" level reset. */

    UPDATE ctl.ETLPackage
    SET    ReadyForExecutionInd = 1
           ,BypassEntryPointInd = @BypassEntryPointPackageInd
           ,IgnoreDependenciesInd = @IgnoreDependenciesInd
           ,LastUpdatedDate = GETDATE()
           ,LastUpdatedUser = SUSER_SNAME()
    WHERE
      @SSISDBFolderName = SSISDBFolderName
      AND @SSISDBProjectName = SSISDBProjectName
      AND @SSISDBPackageName = SSISDBPackageName

    IF @@ROWCOUNT = 0
      THROW 50000, 'The package does not exist. No packages were reset.', 1;

    RETURN 0 
