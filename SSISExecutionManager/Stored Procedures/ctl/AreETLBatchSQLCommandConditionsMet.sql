CREATE PROCEDURE [ctl].[AreETLBatchSQLCommandConditionsMet] (@ETLBatchId          INT,
                                                             @ETLBatchExecutionId INT,
                                                             @ConditionsMetInd    BIT = NULL OUT)
AS
  BEGIN
      --Determine if SQL Command-based Conditons are met
      DECLARE @SQLCommand      NVARCHAR(MAX)
              ,@SQLCommandName VARCHAR(128);

      SET @ConditionsMetInd = 1;

      DECLARE SQLCommandCursor CURSOR FAST_FORWARD FOR
        SELECT
          SQLCommand + ' @ConditionMetInd OUTPUT'
         ,SQLCommandName
        FROM
          ctl.[ETLBatch_SQLCommandCondition] b
          JOIN ctl.SQLCommand sc
            ON b.SQLCommandId = sc.SQLCommandId
        WHERE
          ETLBatchId = @ETLBatchId
          AND b.EnabledInd = 1;

      OPEN SQLCommandCursor

      FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand, @SQLCommandName

      WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @ParamDefinition   NVARCHAR(MAX) = N'@ConditionMetInd BIT OUTPUT'
                    ,@EventDescription VARCHAR(MAX);

            EXECUTE sp_executesql
              @SQLCommand
             ,@ParamDefinition
             ,@ConditionMetInd = @ConditionsMetInd OUT;

            IF @ConditionsMetInd = 0
              BEGIN
                  --Log the failed condition
                  SET @EventDescription = @SQLCommandName + ' condition not met';

                  EXEC [log].[InsertETLBatchExecutionEvent]
                    18
                   ,@ETLBatchExecutionId
				   ,NULL
                   ,@EventDescription;

                  BREAK;
              END
            ELSE
              BEGIN
                  --Log the success condition
                  SET @EventDescription = @SQLCommandName + ' condition met';

                  EXEC [log].[InsertETLBatchExecutionEvent]
                    18
                   ,@ETLBatchExecutionId
                   ,NULL
                   ,@EventDescription;
              END

            FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand, @SQLCommandName
        END

      CLOSE SQLCommandCursor

      DEALLOCATE SQLCommandCursor
  END 
