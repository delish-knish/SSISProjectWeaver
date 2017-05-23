CREATE PROCEDURE [util].[CopyDataFromDB2] @SourceLinkedServerName      VARCHAR(128) = NULL,
                                  @SourceDatabaseName          VARCHAR(128),
                                  @SourceSchemaName            VARCHAR(128),
                                  @SourceTableNamePrefix       VARCHAR(128) = '',
                                  @DestinationLinkedServerName VARCHAR(128) = NULL,
                                  @DestinationDatabaseName     VARCHAR(128) = NULL,
                                  @DestinationSchemaName       VARCHAR(128) = 'dbo',
								  @OnlyPopulateEmptyTablesInd  BIT = 0
AS
  BEGIN
      EXEC msdb.dbo.sp_MSforeachtable
        @command1 = 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'

      SET @SourceDatabaseName = IIF(@SourceLinkedServerName IS NOT NULL, QUOTENAME(@SourceLinkedServerName) + '.', '')
                                + QUOTENAME(@SourceDatabaseName) + '.'
                                + QUOTENAME(@SourceSchemaName);

      SET @DestinationDatabaseName = IIF(@DestinationLinkedServerName IS NOT NULL, QUOTENAME(@DestinationLinkedServerName) + '.', '')
                                     + IIF(@DestinationDatabaseName IS NOT NULL, QUOTENAME(@DestinationDatabaseName) + '.', '')
                                     + QUOTENAME(@DestinationSchemaName)

      DECLARE @SQLTruncate VARCHAR(MAX),
              @SQL         VARCHAR(MAX),
              @TableName   SYSNAME,
              @SchemaName  VARCHAR(MAX),
              @HasIdentity BIT;

      DECLARE TableCursor CURSOR FOR
        SELECT
          s.[name]
          ,t.[name]
        FROM
          sys.tables t
          JOIN sys.schemas s
            ON t.schema_id = s.schema_id
          JOIN sys.objects AS o
            ON t.object_id = o.object_id
          JOIN sys.partitions AS p
            ON o.object_id = p.object_id
        WHERE
          t.type = 'U'
          AND t.[name] LIKE @SourceTableNamePrefix + '%'
		  AND s.[name] = @DestinationSchemaName
        GROUP  BY
          s.[name]
          ,t.[name]
      HAVING SUM(p.rows) = 0 
		OR @OnlyPopulateEmptyTablesInd = 0
      ;

      OPEN TableCursor;

      FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName;

      DECLARE @ColumnList VARCHAR(MAX);

      WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
				SET @SQLTruncate = 'TRUNCATE TABLE ' + QUOTENAME(@SchemaName)
                         + '.' + QUOTENAME(@TableName) + ';';

				EXEC(@SQLTruncate);

			END TRY
            BEGIN CATCH
                SET @SQLTruncate = 'DELETE FROM ' + QUOTENAME(@SchemaName)
                         + '.' + QUOTENAME(@TableName) + ';';

				EXEC(@SQLTruncate);
            END CATCH

			BEGIN TRY
                SET @ColumnList = NULL;

                SET @HasIdentity = (SELECT
                                      SUM(CAST(is_identity AS TINYINT))
                                    FROM
                                      sys.columns
                                    WHERE
                                     object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.'
                                                           + QUOTENAME(@TableName)));

                SELECT
                  @ColumnList = COALESCE(@ColumnList + ',', '')
                                + QUOTENAME([name])
                FROM
                  sys.columns
                WHERE
                  object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.'
                                        + QUOTENAME(@TableName))
                  AND is_computed = 0 --Don't populate computed columns
                  AND [name] NOT IN ( 'CreatedDate', 'CreatedUser', 'LastUpdatedDate', 'LastUpdatedUser', 'SSISDBExecutionId' ); --ignore audit columns

                PRINT CHAR(13) + CHAR(10)
                      + '-----------------------'
                      + QUOTENAME(@SchemaName) + '.'
                      + QUOTENAME(@TableName)
                      + '-----------------------'

                SET @SQL = IIF(@HasIdentity = 1, 'SET IDENTITY_INSERT ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' ON;', '')
                           + 'INSERT INTO ' + @DestinationDatabaseName + '.' + @TableName + ' (' + @ColumnList
                           + ') SELECT ' + @ColumnList + ' FROM '
                           + CONVERT(VARCHAR, @SourceDatabaseName) + '.'
                           + QUOTENAME(@TableName) + ' '
                           + IIF(@HasIdentity = 1, 'SET IDENTITY_INSERT ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' OFF ', '')
                           + ';';

                PRINT @SQL;

                EXEC(@SQL);
            END TRY
            BEGIN CATCH
                PRINT ERROR_MESSAGE();
            END CATCH

            FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName;;
        END

      CLOSE TableCursor;

      DEALLOCATE TableCursor;

      EXEC sp_MSforeachtable
        @command1 = 'ALTER TABLE ? CHECK CONSTRAINT ALL';

      RETURN 0
  END 
