CREATE PROCEDURE [cfg].[DeleteSQLCommand]	@SQLCommandId INT
AS
    DELETE FROM ctl.SQLCommand
    WHERE  SQLCommandId = @SQLCommandId

    RETURN 0 
