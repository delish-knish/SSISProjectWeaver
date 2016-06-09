CREATE PROCEDURE [sup].[EnableDisableProjectPackage] @SSISDBFolderName  VARCHAR(128),
                                                     @SSISDBProjectName VARCHAR(128),
                                                     @SSISDBPackageName VARCHAR (260) = NULL,
                                                     @EnabledInd        BIT,
                                                     @Comments          VARCHAR(MAX)
AS
    /*The purpose of this stored procedure is to enable/disable a project (all packages within the project) or a package so that it will be added/removed from currently running 
    and future batches until it is enabled/disabled again. */

    IF @EnabledInd = 0
       AND ( @Comments IS NULL
              OR RTRIM(LTRIM(@Comments)) = '' )
      BEGIN
          DECLARE @ErrorDescriptionMissingComments NVARCHAR(500) = 'A comment must be supplied when disabling projects/packages.';

          THROW 50000, @ErrorDescriptionMissingComments, 1;
      END

    UPDATE ctl.ETLPackage
    SET    EnabledInd = @EnabledInd
           ,Comments = @Comments
           ,LastUpdatedDate = GETDATE()
           ,LastUpdatedUser = SUSER_SNAME()
    WHERE
      @SSISDBFolderName = SSISDBFolderName
      AND @SSISDBProjectName = SSISDBProjectName
      AND ( @SSISDBPackageName = SSISDBPackageName
             OR @SSISDBPackageName IS NULL )

    IF @@ROWCOUNT = 0
      BEGIN
          DECLARE @ErrorDescriptionRowCount NVARCHAR(500) = 'The project/package does not exist. No project/packages were ' + IIF(@EnabledInd = 1, 'enabled', 'disabled') + '.';

          THROW 50000, @ErrorDescriptionRowCount, 1;
      END

    RETURN 0 
