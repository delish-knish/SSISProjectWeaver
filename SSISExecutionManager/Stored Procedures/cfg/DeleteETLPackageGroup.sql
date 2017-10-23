CREATE PROCEDURE [cfg].[DeleteETLPackageGroup]	@ETLPackageGroupId INT
AS
    DELETE FROM [cfg].[ETLPackageGroup]
    WHERE  [ETLPackageGroupId] = @ETLPackageGroupId

    RETURN 0 
