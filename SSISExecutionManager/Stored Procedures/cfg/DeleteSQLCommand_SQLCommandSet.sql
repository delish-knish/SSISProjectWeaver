CREATE PROCEDURE [cfg].[DeleteSQLCommand_SQLCommandSet] @SQLCommandId    INT,
                                                        @SQLCommandSetId INT
AS
    DELETE FROM ctl.SQLCommand_SQLCommandSet
    WHERE  SQLCommandId = @SQLCommandId
           AND SQLCommandSetId = @SQLCommandSetId

    RETURN 0 
