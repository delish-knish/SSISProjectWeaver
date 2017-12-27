CREATE PROCEDURE [cfg].[DeleteETLPackageGroup_ETLPackage_SQLCommandCondition] @ETLPackageGroup_ETLPackageId   INT,
                                                                       @SQLCommandId INT
AS
    DELETE FROM [cfg].[ETLPackageGroup_ETLPackage_SQLCommandCondition]
    WHERE  ETLPackageGroup_ETLPackageId = @ETLPackageGroup_ETLPackageId
           AND SQLCommandId = @SQLCommandId

    RETURN 0 
