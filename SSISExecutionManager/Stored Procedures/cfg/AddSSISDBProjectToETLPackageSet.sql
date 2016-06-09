CREATE PROCEDURE [cfg].[AddSSISDBProjectToETLPackageSet] @SSISDBFolderName  VARCHAR(128),
                                                         @SSISDBProjectName VARCHAR(128),
                                                         @ETLPackageSetId   INT
AS
    INSERT INTO [ctl].[ETLPackage_ETLPackageSet]
                (ETLPackageId
                 ,ETLPackageSetId)
    SELECT
      ep.ETLPackageId
      ,@ETLPackageSetId
    FROM
      ctl.ETLPackage ep
    WHERE
      SSISDBFolderName = @SSISDBFolderName
      AND SSISDBProjectName = @SSISDBProjectName

    RETURN 0 
