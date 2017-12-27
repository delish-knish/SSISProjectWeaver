CREATE PROCEDURE [cfg].[AddSSISDBProjectToETLPackageGroup] @SSISDBFolderName  VARCHAR(128),
                                                         @SSISDBProjectName VARCHAR(128),
                                                         @ETLPackageGroupId   INT
AS
    INSERT INTO [cfg].[ETLPackageGroup_ETLPackage]
                (ETLPackageId
                 ,[ETLPackageGroupId])
    SELECT
      ep.ETLPackageId
      ,@ETLPackageGroupId
    FROM
      [cfg].ETLPackage ep
    WHERE
      SSISDBFolderName = @SSISDBFolderName
      AND SSISDBProjectName = @SSISDBProjectName

    RETURN 0 
