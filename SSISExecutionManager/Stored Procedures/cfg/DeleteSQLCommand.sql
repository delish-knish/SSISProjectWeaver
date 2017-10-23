CREATE PROCEDURE [cfg].[DeleteSQLCommand]	@SQLCommandId INT
AS
    DELETE FROM [cfg].SQLCommand
    WHERE  SQLCommandId = @SQLCommandId

    RETURN 0 
