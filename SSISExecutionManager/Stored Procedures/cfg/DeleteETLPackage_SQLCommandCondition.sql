CREATE PROCEDURE [cfg].[DeleteETLPackage_SQLCommandCondition]	@ETLPackageId INT,
																@SQLCommandId INT
AS
    DELETE FROM ctl.[ETLPackage_SQLCommandCondition]
    WHERE  ETLPackageId = @ETLPackageId
           AND SQLCommandId = @SQLCommandId

    RETURN 0 
