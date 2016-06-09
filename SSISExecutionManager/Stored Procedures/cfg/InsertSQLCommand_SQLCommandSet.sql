CREATE PROCEDURE [cfg].[InsertSQLCommand_SQLCommandSet] @SQLCommandId               INT,
                                                        @SQLCommandSetId            INT,
                                                        @EnabledInd                 BIT,
                                                        @SQLCommandDependencyTypeId INT
AS
    INSERT INTO [ctl].[SQLCommand_SQLCommandSet]
                (SQLCommandId
                 ,SQLCommandSetId
                 ,EnabledInd
                 ,SQLCommandDependencyTypeId)
    VALUES      (@SQLCommandId
                 ,@SQLCommandSetId
                 ,@EnabledInd
                 ,@SQLCommandDependencyTypeId)

    RETURN 0 
