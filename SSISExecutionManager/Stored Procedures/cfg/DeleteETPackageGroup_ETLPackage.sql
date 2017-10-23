CREATE PROCEDURE [cfg].[DeleteETLPackageGroup_ETLPackage] @ETLPackageId    INT,
															 @ETLPackageGroupId INT
AS
    DELETE FROM [cfg].[ETLPackageGroup_ETLPackage]
    WHERE  ETLPackageId = @ETLPackageId
           AND [ETLPackageGroupId] = @ETLPackageGroupId

    RETURN 0 
