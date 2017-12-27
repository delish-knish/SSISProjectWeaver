CREATE PROCEDURE [cfg].[RemoveSSISDBProjecFromETLPackageGroup] @SSISDBFolderName  VARCHAR(128),
                                                             @SSISDBProjectName VARCHAR(128),
                                                             @ETLPackageGroupId INT
AS
    DELETE epeps
    FROM   [cfg].[ETLPackageGroup_ETLPackage] epeps
           JOIN [cfg].ETLPackage ep
             ON epeps.ETLPackageId = ep.ETLPackageId
    WHERE  SSISDBFolderName = @SSISDBFolderName
           AND SSISDBProjectName = @SSISDBProjectName
           AND [ETLPackageGroupId] = @ETLPackageGroupId

    RETURN 0 
