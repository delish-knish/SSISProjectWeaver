CREATE PROCEDURE [cfg].[RemoveSSISDBProjecFromETLPackageSet] @SSISDBFolderName  VARCHAR(128),
                                                             @SSISDBProjectName VARCHAR(128),
                                                             @ETLPackageSetId   INT
AS
    DELETE epeps
    FROM   [ctl].[ETLPackage_ETLPackageSet] epeps
           JOIN ctl.ETLPackage ep
             ON epeps.ETLPackageId = ep.ETLPackageId
    WHERE  SSISDBFolderName = @SSISDBFolderName
           AND SSISDBProjectName = @SSISDBProjectName
           AND ETLPackageSetId = @ETLPackageSetId

    RETURN 0 
