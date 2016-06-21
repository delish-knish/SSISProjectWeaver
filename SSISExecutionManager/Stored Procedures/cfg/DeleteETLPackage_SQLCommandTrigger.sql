CREATE PROCEDURE [cfg].[DeleteETLPackage_SQLCommandTrigger]	@ETLPackageId INT,
																@SQLCommandId INT
AS
    DELETE FROM ctl.[ETLPackage_SQLCommandTrigger]
    WHERE  ETLPackageId = @ETLPackageId
           AND SQLCommandId = @SQLCommandId

    RETURN 0 
