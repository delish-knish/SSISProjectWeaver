CREATE PROCEDURE [cfg].[RemoveSSISDBProjecFromETLPackageGroup] @SSISDBFolderName  VARCHAR(128),
                                                             @SSISDBProjectName VARCHAR(128),
                                                             @ETLPackageGroupId INT
AS
    DELETE epeps
    FROM   [ctl].[ETLPackageGroup_ETLPackage] epeps
           JOIN ctl.ETLPackage ep
             ON epeps.ETLPackageId = ep.ETLPackageId
    WHERE  SSISDBFolderName = @SSISDBFolderName
           AND SSISDBProjectName = @SSISDBProjectName
           AND [ETLPackageGroupId] = @ETLPackageGroupId

    RETURN 0 
