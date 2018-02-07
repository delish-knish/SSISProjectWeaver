CREATE PROCEDURE [etl].[InsertForeignKeyConstraintViolations] @TargetDatabaseName VARCHAR(128),
                                                              @TargetSchemaName   VARCHAR(128) = 'dbo'
AS
    SET NOCOUNT ON;

    DECLARE @CurrentDatabaseName NVARCHAR(250) = DB_NAME();

    TRUNCATE TABLE [log].[ForeignKeyConstraintViolation];

    CREATE TABLE #CheckConstraints
      (
         TableName      SYSNAME
        ,ConstraintName SYSNAME
        ,WHEREClause    VARCHAR(1000)
      );

    INSERT INTO #CheckConstraints
    EXEC ('USE ' + @TargetDatabaseName + '; DBCC CHECKCONSTRAINTS; USE ' + @CurrentDatabaseName + ';');

    DECLARE @SQLConstraints NVARCHAR(4000) = '
    INSERT [log].[ForeignKeyConstraintViolation]
           (DatabaseName,
		    TableName,
            ColumnName,
            ConstraintName,
            RelatedTableName,
            InvalidValue,
            OccurrenceCount)
    SELECT
      rc.CONSTRAINT_CATALOG AS DatabaseName
	  ,TableName
      ,SUBSTRING (WHEREClause, 1, CHARINDEX (''='', WHEREClause, 1) - 1)                                                                                         AS ColumnName
      ,ConstraintName
      ,QUOTENAME(parent.TABLE_SCHEMA) + ''.''
       + QUOTENAME(parent.TABLE_NAME)                                                                                                                          AS RelatedTableName
      ,RTRIM(LTRIM(REPLACE (SUBSTRING (WHEREClause, CHARINDEX (''='', WHEREClause, 1) + 1, LEN (WHEREClause) - CHARINDEX (''='', WHEREClause, 1) - 1), '''''''', ''''))) AS InvalidValue
      ,0                                                                                                                                                       AS OccurrenceCount
    FROM
      #CheckConstraints cc
      JOIN ' + @TargetDatabaseName + '.INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
        ON cc.ConstraintName = QUOTENAME(rc.CONSTRAINT_NAME)
           AND ''' + @TargetDatabaseName
      + ''' = rc.CONSTRAINT_CATALOG
           AND ''' + @TargetSchemaName + ''' = rc.CONSTRAINT_SCHEMA
	  JOIN ' + @TargetDatabaseName + '.INFORMATION_SCHEMA.KEY_COLUMN_USAGE parent
        ON rc.UNIQUE_CONSTRAINT_NAME = parent.CONSTRAINT_NAME
           AND ''' + @TargetDatabaseName
      + ''' = parent.CONSTRAINT_CATALOG
           AND ''' + @TargetSchemaName + ''' = parent.CONSTRAINT_SCHEMA;'

    EXEC (@SQLConstraints);

    DROP TABLE #CheckConstraints;

    DECLARE @ConstraintName VARCHAR(128)
            ,@TableName     VARCHAR(128)
            ,@ColumnName    VARCHAR(128)
            ,@InvalidValue  NVARCHAR(4000)
    DECLARE FKConstraintCursor CURSOR FAST_FORWARD FOR
      SELECT
        ConstraintName
       ,TableName
       ,ColumnName
       ,InvalidValue
      FROM
        [log].[ForeignKeyConstraintViolation]
      ORDER  BY
        TableName

    OPEN FKConstraintCursor;

    FETCH NEXT FROM FKConstraintCursor INTO @ConstraintName, @TableName, @ColumnName, @InvalidValue;

    WHILE @@FETCH_STATUS = 0
      BEGIN
          DECLARE @SQLViolationCount NVARCHAR(4000) = 'SELECT ' + @ColumnName + ', COUNT(*) AS OccurrenceCount FROM ' + @TargetDatabaseName + '.' + @TableName + ' WHERE '
            + @ColumnName + ' = ''' + @InvalidValue + ''' GROUP BY ' + @ColumnName;
          DECLARE @CountTable TABLE
            (
               InvalidValue    NVARCHAR(4000)
              ,OccurrenceCount INT
            )

          INSERT @CountTable
          EXEC (@SQLViolationCount);

          UPDATE v
          SET    OccurrenceCount = ct.OccurrenceCount
          FROM   [log].[ForeignKeyConstraintViolation] v
                 JOIN @CountTable ct
                   ON v.ConstraintName = @ConstraintName
                      AND v.InvalidValue = ct.InvalidValue

          FETCH NEXT FROM FKConstraintCursor INTO @ConstraintName, @TableName, @ColumnName, @InvalidValue;
      END

    CLOSE FKConstraintCursor;

    DEALLOCATE FKConstraintCursor;

    RETURN 0 
