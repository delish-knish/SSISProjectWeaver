CREATE PROCEDURE [log].[InsertETLPackageExecutionRowLevelError](@TableProcessRowKey VARCHAR(250),
                                                                @LookupTableName    VARCHAR(250),
                                                                @LookupTableRowKey  VARCHAR(250),
                                                                @ParentProcessName  VARCHAR(250),
                                                                @TargetTableName    VARCHAR(250),
                                                                @Description        VARCHAR(1000))
AS
  BEGIN
      DECLARE @ETLPackageExecutionRowLevelErrorId BIGINT

      INSERT INTO [log].ETLPackageExecutionRowLevelError
                  (TableProcessRowKey
                  ,LookupTableName
                  ,LookupTableRowKey
				  ,ParentProcessName
				  ,TargetTableName
                  ,[Description]
                  ,ErrorDateTime)
      VALUES      ( @TableProcessRowKey
                   ,@LookupTableName
                   ,@LookupTableRowKey
				   ,@ParentProcessName
				   ,@TargetTableName
                   ,@Description
                   ,GETDATE())

      SET @ETLPackageExecutionRowLevelErrorId = SCOPE_IDENTITY();

      SELECT
        @ETLPackageExecutionRowLevelErrorId AS ETLPackageExecutionRowLevelErrorId;
  END

RETURN 0 
