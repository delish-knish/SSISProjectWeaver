CREATE PROCEDURE [util].[CopyDatabase]@SourceLinkedServerName     VARCHAR(128) = NULL,
                                      @SourceDatabaseName         VARCHAR(128),
                                      @SourceSchemaName           VARCHAR(128),
                                      @SourceTableNamePrefix      VARCHAR(128) = '',
                                      @TargetLinkedServerName     VARCHAR(128) = NULL,
                                      @TargetDatabaseName         VARCHAR(128) = NULL,
                                      @TargetSchemaName           VARCHAR(128) = 'dbo',
                                      @OnlyPopulateEmptyTablesInd BIT = 0
AS
  BEGIN
      SET NOCOUNT ON;

      DECLARE @SQLCursorData        NVARCHAR(MAX)
              ,@SQLTruncate         VARCHAR(MAX)
              ,@SQL                 VARCHAR(MAX)
              ,@TableName           SYSNAME
              ,@SchemaName          VARCHAR(MAX)
              ,@HasIdentity         BIT
              ,@CurrentDatabaseName VARCHAR(128) = DB_NAME()
              ,@TargetDatabase      VARCHAR(128) = @TargetDatabaseName; --ToDo: Cleanup confusing names  
      DECLARE @SQLNoCheck NVARCHAR(4000) = 'USE ' + @TargetDatabase
        + '; EXEC sp_MSforeachtable @command1 = ''ALTER TABLE ? NOCHECK CONSTRAINT ALL''; USE '
        + @CurrentDatabaseName + ';';

      EXEC sp_executesql
        @SQLNoCheck;

      SET @SourceDatabaseName = IIF(@SourceLinkedServerName IS NOT NULL, QUOTENAME(@SourceLinkedServerName) + '.', '')
                                + QUOTENAME(@SourceDatabaseName) + '.'
                                + QUOTENAME(@SourceSchemaName);
      SET @TargetDatabaseName = IIF(@TargetLinkedServerName IS NOT NULL, QUOTENAME(@TargetLinkedServerName) + '.', '')
                                + IIF(@TargetDatabaseName IS NOT NULL, QUOTENAME(@TargetDatabaseName) + '.', '')
                                + QUOTENAME(@TargetSchemaName)
      SET @SQLCursorData = 'DECLARE TableCursor CURSOR GLOBAL FOR
        SELECT
          s.NAME
          ,t.NAME
        FROM ' + @TargetDatabase
                           + '.sys.tables t
          JOIN ' + @TargetDatabase
                           + '.sys.schemas s
            ON t.schema_id = s.schema_id
          JOIN ' + @TargetDatabase
                           + '.sys.objects AS o
            ON t.object_id = o.object_id
          JOIN ' + @TargetDatabase
                           + '.sys.partitions AS p
            ON o.object_id = p.object_id
        WHERE
          t.type = ''U''
          AND t.NAME LIKE ''' + @SourceTableNamePrefix + '%''
		   AND s.NAME = ''' + @SourceSchemaName + '''
        GROUP  BY
          s.NAME
          ,t.NAME
      HAVING SUM(p.rows) = 0 
  OR '
                           + CAST(@OnlyPopulateEmptyTablesInd AS VARCHAR(1))
                           + ' = 0;'

      EXEC sp_executesql
        @SQLCursorData;

      OPEN TableCursor;

      FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName;

      DECLARE @ColumnList VARCHAR(MAX);

      WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                PRINT CHAR(13) + CHAR(10)
                      + '-----------------------'
                      + QUOTENAME(@SchemaName) + '.'
                      + QUOTENAME(@TableName)
                      + '-----------------------'

                --ToDo: Add logic to determine if there are FK constraints. TRUNCATE if not, DELETE if there are.
                IF ( @OnlyPopulateEmptyTablesInd = 0 )
                  BEGIN
                      SET @SQLTruncate = 'DELETE FROM ' + QUOTENAME(@TargetDatabase)
                                         + '.' + QUOTENAME(@SchemaName) + '.'
                                         + QUOTENAME(@TableName) + ';';

                      EXEC(@SQLTruncate);

                      PRINT CAST(@@ROWCOUNT AS VARCHAR)
                            + ' rows deleted.';
                  END

                DECLARE @SQLHasIdentity NVARCHAR(1000) = 'USE ' + @TargetDatabase
                  + '; 
      SELECT @val = CAST(SUM(CAST(is_identity AS TINYINT)) AS BIT)
                        FROM '
                  + @TargetDatabase
                  + '.sys.columns
                        WHERE object_id = OBJECT_ID(QUOTENAME('''
                  + @SchemaName + ''') + ''.'' + QUOTENAME('''
                  + @TableName + ''')); 
      USE '
                  + @CurrentDatabaseName + ';';

                EXEC sp_executesql
                  @SQLHasIdentity,
                  N'@val bit OUTPUT',
                  @val = @HasIdentity OUTPUT;

                SET @ColumnList = NULL;

                DECLARE @SQLColumnList NVARCHAR(4000) = 'USE ' + @TargetDatabase + '; 
     DECLARE @ColList NVARCHAR(MAX);
     SELECT @val = COALESCE(@val + '','', '''') + QUOTENAME(name)
     FROM '
                  + @TargetDatabase
                  + '.sys.columns
     WHERE
       object_id = OBJECT_ID(QUOTENAME('''
                  + @SchemaName + ''') + ''.'' + QUOTENAME('''
                  + @TableName + '''))
       AND is_computed = 0 
       AND NAME NOT IN ( ''CreatedDate'', ''CreatedUser'', ''LastUpdatedDate'', ''LastUpdatedUser'' ); 
       USE '
                  + @CurrentDatabaseName + ';';

                EXECUTE sp_executesql
                  @SQLColumnList,
                  N'@val VARCHAR(MAX) OUTPUT',
                  @val = @ColumnList OUTPUT;

                SET @SQL = 'SET NOCOUNT ON;' + IIF(@HasIdentity = 1, 'SET IDENTITY_INSERT ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' ON;', '')
                           + 'INSERT INTO ' + @TargetDatabaseName + '.'
                           + @TableName + ' (' + @ColumnList + ') SELECT '
                           + @ColumnList + ' FROM '
                           + CONVERT(VARCHAR, @SourceDatabaseName) + '.'
                           + QUOTENAME(@TableName) + ' '
						   + '; PRINT CAST(@@ROWCOUNT AS VARCHAR) + '' rows inserted.'';'
                           + IIF(@HasIdentity = 1, 'SET IDENTITY_INSERT ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' OFF ', '');
                           

                EXEC(@SQL);

                
            END TRY
            BEGIN CATCH
                PRINT ERROR_MESSAGE();
            END CATCH

            FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName;;
        END

      CLOSE TableCursor;

      DEALLOCATE TableCursor;

      DECLARE @SQLCheck NVARCHAR(4000) = 'SET NOCOUNT ON; USE ' + @TargetDatabase
        + '; EXEC sp_MSforeachtable @command1 = ''ALTER TABLE ? CHECK CONSTRAINT ALL''; USE '
        + @CurrentDatabaseName + ';';

      EXEC sp_executesql
        @SQLCheck;

      RETURN 0
  END

RETURN 0 
