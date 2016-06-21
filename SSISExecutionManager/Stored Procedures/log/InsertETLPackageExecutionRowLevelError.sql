CREATE PROCEDURE [log].[InsertETLPackageExecutionRowLevelError](@TableProcessRowKey             VARCHAR(250),
                                                               @LookupTableName                VARCHAR(250),
                                                               @LookupTableRowKey              VARCHAR(250),
                                                               @Comment                        VARCHAR(1000))
AS
  BEGIN
      DECLARE @ETLPackageExecutionRowLevelErrorId BIGINT

      INSERT INTO [log].ETLPackageExecutionRowLevelError
                  (TableProcessRowKey
                   ,LookupTableName
                   ,LookupTableRowKey
                   ,Comment
                   ,ErrorDateTime)
      VALUES      ( @TableProcessRowKey
                    ,@LookupTableName
                    ,@LookupTableRowKey
                    ,@Comment
                    ,GETDATE())

      SET @ETLPackageExecutionRowLevelErrorId = SCOPE_IDENTITY();

      SELECT
        @ETLPackageExecutionRowLevelErrorId AS ETLPackageExecutionRowLevelErrorId;
  END
RETURN 0
