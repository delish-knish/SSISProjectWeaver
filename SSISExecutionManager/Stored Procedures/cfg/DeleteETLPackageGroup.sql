CREATE PROCEDURE [cfg].[DeleteETLPackageGroup]	@ETLPackageGroupId INT
AS
    DELETE FROM ctl.[ETLPackageGroup]
    WHERE  [ETLPackageGroupId] = @ETLPackageGroupId

    RETURN 0 
