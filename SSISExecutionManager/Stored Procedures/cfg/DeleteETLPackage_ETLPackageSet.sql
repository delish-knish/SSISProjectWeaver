CREATE PROCEDURE [cfg].[DeleteETLPackage_ETLPackageSet] @ETLPackageId    INT,
                                                        @ETLPackageSetId INT
AS
    DELETE FROM ctl.ETLPackage_ETLPackageSet
    WHERE  ETLPackageId = @ETLPackageId
           AND ETLPackageSetId = @ETLPackageSetId

    RETURN 0 
