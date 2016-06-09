CREATE PROCEDURE [sup].[ResetProjectPackageToDefaultSettings] @SSISDBFolderName  VARCHAR(128),
                                                              @SSISDBProjectName VARCHAR(128) = NULL,
                                                              @SSISDBPackageName VARCHAR (260) = NULL
AS
    /*The purpose of this stored procedure is to reset indicators on packages to a "normal execution" state.*/

    UPDATE ctl.ETLPackage
    SET    BypassEntryPointInd = 0
           ,IgnoreDependenciesInd = 0
           ,ReadyForExecutionInd = NULL
           ,LastUpdatedDate = GETDATE()
           ,LastUpdatedUser = SUSER_SNAME()
    WHERE
      @SSISDBFolderName = SSISDBFolderName
      AND ( @SSISDBProjectName = SSISDBProjectName
             OR @SSISDBProjectName IS NULL )
      AND ( @SSISDBPackageName = SSISDBPackageName
             OR @SSISDBPackageName IS NULL )

    IF @@ROWCOUNT = 0
      THROW 50000, 'The project/package does not exist. No packages were reset.', 1;

    IF @SSISDBPackageName IS NOT NULL
       AND @SSISDBProjectName IS NULL
      THROW 50000, 'A project name must be specified if a package name is specified. No packages were reset.', 1;

    RETURN 0 
