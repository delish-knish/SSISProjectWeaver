CREATE PROCEDURE [sup].[EnableDisableProjectPackage] @SSISDBFolderName  NVARCHAR(128),
                                                     @SSISDBProjectName NVARCHAR(128),
                                                     @SSISDBPackageName NVARCHAR (260) = NULL,
                                                     @EnabledInd        BIT,
                                                     @Comments          VARCHAR(MAX)
AS
    /*The purpose of this stored procedure is to enable/disable a project (all packages within the project) or a package so that it will be added/removed from currently running 
    and future batches until it is enabled/disabled again. */

	--TODO: Enhance this proc to be at the etl package group level.

    IF @EnabledInd = 0
       AND ( @Comments IS NULL
              OR RTRIM(LTRIM(@Comments)) = '' )
      BEGIN
          DECLARE @ErrorDescriptionMissingComments NVARCHAR(500) = 'A comment must be supplied when disabling projects/packages.';

          THROW 50000, @ErrorDescriptionMissingComments, 1;
      END

    UPDATE epgep
    SET    EnabledInd = @EnabledInd
           ,Comments = @Comments
           ,LastUpdatedDate = GETDATE()
           ,LastUpdatedUser = SUSER_SNAME()
	FROM 
		ctl.ETLPackageGroup_ETLPackage epgep
		JOIN ctl.ETLPackage ep ON epgep.ETLPackageId = ep.ETLPackageId
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
