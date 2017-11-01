CREATE PROCEDURE [sup].[ResetProjectPackageToDefaultSettings] @SSISDBFolderName  NVARCHAR(128),
                                                              @SSISDBProjectName NVARCHAR(128) = NULL,
                                                              @SSISDBPackageName NVARCHAR (260) = NULL
AS
    /*The purpose of this stored procedure is to reset indicators on packages to a "normal execution" state.*/

    UPDATE epgep
    SET    [BypassEntryPointDefaultInd] = 0
           ,[IgnoreDependenciesDefaultInd] = 0
           ,ReadyForExecutionInd = NULL
           ,LastUpdatedDate = GETDATE()
           ,LastUpdatedUser = SUSER_SNAME()
    FROM   [cfg].ETLPackageGroup_ETLPackage epgep
           JOIN [cfg].ETLPackage ep
             ON epgep.ETLPackageId = ep.ETLPackageId
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
