CREATE PROCEDURE [cfg].[InsertETLPackage_ETLPackageSet] @ETLPackageId    INT,
                                                        @ETLPackageSetId INT
AS
    INSERT INTO [ctl].[ETLPackage_ETLPackageSet]
                (ETLPackageId
                 ,ETLPackageSetId)
    VALUES     (@ETLPackageId
                ,@ETLPackageSetId)

    RETURN 0 
