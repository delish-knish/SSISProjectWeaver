CREATE PROCEDURE [cfg].[DeleteETLPackageGroup_SQLCommand]	@ETLPackageGroupId INT,
														@SQLCommandId INT
AS
    DELETE FROM ctl.[ETLPackageGroup_SQLCommand]
    WHERE  [ETLPackageGroupId] = @ETLPackageGroupId
           AND SQLCommandId = @SQLCommandId

    RETURN 0 
