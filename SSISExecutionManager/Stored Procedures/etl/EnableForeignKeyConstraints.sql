CREATE PROCEDURE [etl].[EnableForeignKeys] @TargetDatabaseName VARCHAR(128),
                                           @WithCheckInd       BIT,
                                           @TableName          VARCHAR(128) = NULL
AS
    SET NOCOUNT ON;

    DECLARE @CurrentDatabaseName NVARCHAR(250) = DB_NAME()
            ,@WithCheckClause    NVARCHAR(100) = IIF(@WithCheckInd = 1, ' WITH CHECK ', '');

    IF @TableName IS NULL
      BEGIN
          DECLARE @ConstraintName SYSNAME;

          CREATE TABLE #CheckConstraints
            (
               TableName      SYSNAME
              ,ConstraintName SYSNAME
            );

          INSERT INTO #CheckConstraints
          EXEC ('SELECT
			child.TABLE_NAME  AS TableName
			,rc.CONSTRAINT_NAME AS ConstraintName
		  FROM
			' + @TargetDatabaseName + '.INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
			JOIN ' + @TargetDatabaseName + '.INFORMATION_SCHEMA.KEY_COLUMN_USAGE child
			  ON rc.CONSTRAINT_NAME = child.CONSTRAINT_NAME
				 AND rc.CONSTRAINT_CATALOG = child.CONSTRAINT_CATALOG
				 AND rc.CONSTRAINT_SCHEMA = child.CONSTRAINT_SCHEMA;');

          DECLARE FKConstraintCursor CURSOR FAST_FORWARD FOR
            SELECT
              TableName
             ,ConstraintName
            FROM
              #CheckConstraints;

          OPEN FKConstraintCursor;

          FETCH NEXT FROM FKConstraintCursor INTO @TableName, @ConstraintName;

          WHILE @@FETCH_STATUS = 0
            BEGIN
                BEGIN TRY
                    EXEC ('USE ' + @TargetDatabaseName + '; ALTER TABLE ' + @TableName + @WithCheckClause + ' CHECK CONSTRAINT ' + @ConstraintName +'; USE ' + @CurrentDatabaseName + ';');
                END TRY
                BEGIN CATCH
                    EXEC ('USE ' + @TargetDatabaseName + '; ALTER TABLE ' + @TableName + ' CHECK CONSTRAINT ' + @ConstraintName +'; USE ' + @CurrentDatabaseName + ';');
                    PRINT ERROR_MESSAGE();
                END CATCH

                FETCH NEXT FROM FKConstraintCursor INTO @TableName, @ConstraintName;
            END

      END
    ELSE
      BEGIN
          EXEC ('USE ' + @TargetDatabaseName + '; ALTER TABLE ' + @TableName + @WithCheckClause + 'CHECK CONSTRAINT ALL; USE ' + @CurrentDatabaseName + ';');
      END

    RETURN 0 
