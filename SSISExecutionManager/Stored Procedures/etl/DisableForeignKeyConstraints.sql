CREATE PROCEDURE [etl].[DisableForeignKeyConstraints] @TargetDatabaseName VARCHAR(128),
                                            @TableName          VARCHAR(128) = NULL
AS
    SET NOCOUNT ON;

    DECLARE @CurrentDatabaseName NVARCHAR(250) = DB_NAME();

    IF @TableName IS NULL
      BEGIN
          EXEC ('USE ' + @TargetDatabaseName + '; EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT ALL"; USE ' + @CurrentDatabaseName + ';');
      END
    ELSE
      BEGIN
          EXEC ('USE ' + @TargetDatabaseName + '; ALTER TABLE ' + @TableName + ' NOCHECK CONSTRAINT ALL; USE ' + @CurrentDatabaseName + ';');
      END

    RETURN 0 
