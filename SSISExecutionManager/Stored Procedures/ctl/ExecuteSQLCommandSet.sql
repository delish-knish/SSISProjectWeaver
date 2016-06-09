CREATE PROCEDURE [ctl].[ExecuteSQLCommandSet] @ETLBatchId                 INT,
                                              @SQLCommandSetId            INT,
                                              @SQLCommandDependencyTypeId INT,
                                              @EndETLBatchExecutionInd    BIT OUT
AS
    DECLARE @SQLCommand                               NVARCHAR(MAX),
            @SQLCommandName                           VARCHAR(128),
            @RequiresETLBatchIdParameterInd           BIT,
            @RequiresEndETLBatchExecutionParameterInd BIT,
            @FailBatchOnFailureInd                    BIT,
            @EventDescription                         VARCHAR(MAX);

    DECLARE SQLCommandCursor CURSOR FAST_FORWARD FOR
      SELECT
        SQLCommand
        ,SQLCommandName
        ,RequiresETLBatchIdParameterInd
        ,RequiresEndETLBatchExecutionParameterInd
        ,FailBatchOnFailureInd
      FROM
        ctl.SQLCommand sc
        JOIN ctl.SQLCommand_SQLCommandSet scscs
          ON sc.SQLCommandId = scscs.SQLCommandId
      WHERE
        scscs.SQLCommandSetId = @SQLCommandSetId
        AND scscs.SQLCommandDependencyTypeId = @SQLCommandDependencyTypeId
        AND scscs.EnabledInd = 1
      ORDER  BY
        ExecutionOrder;

    OPEN SQLCommandCursor

    FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand, @SQLCommandName, @RequiresETLBatchIdParameterInd, @RequiresEndETLBatchExecutionParameterInd, @FailBatchOnFailureInd;

    WHILE @@FETCH_STATUS = 0
      BEGIN
          --Execute the SQL Command
          SET @EventDescription = 'Executing SQL Command "' + @SQLCommandName + '"';

          EXEC [log].InsertETLBatchEvent 15,@ETLBatchId,NULL,@EventDescription;

          --Use a TRY/CATCH block so that we can continue executing upon failure
          BEGIN TRY
              DECLARE @SQLCommandHasParamsInd BIT = ( IIF(CHARINDEX('@', @SQLCommand) > 0, 1, 0) );

              SET @SQLCommand = @SQLCommand + IIF(@RequiresETLBatchIdParameterInd = 1 AND @SQLCommandHasParamsInd = 1, ',', '') + IIF(@RequiresETLBatchIdParameterInd = 1, '@ETLBatchId = ' + CAST(@ETLBatchId AS VARCHAR(10)), '');

              SET @SQLCommand = @SQLCommand + IIF(@RequiresEndETLBatchExecutionParameterInd = 1 AND @SQLCommandHasParamsInd = 1, ',', '') + IIF(@RequiresEndETLBatchExecutionParameterInd = 1, '@EndETLBatchExecutionInd = @EndETLBatchExecutionInd OUTPUT', '');

              IF @RequiresEndETLBatchExecutionParameterInd = 1
                BEGIN
                    DECLARE @ParamDefinition NVARCHAR(MAX) = N'@EndETLBatchExecutionInd BIT OUTPUT';

                    EXECUTE sp_executesql @SQLCommand,@ParamDefinition,@EndETLBatchExecutionInd = @EndETLBatchExecutionInd OUT;
                END
              ELSE
                EXECUTE sp_executesql @SQLCommand;

              IF @EndETLBatchExecutionInd = 1
                BREAK;
          END TRY

          BEGIN CATCH
              SET @EventDescription = 'Error while attempting to execute SQL Command "' + @SQLCommandName + '" Error: ' + ERROR_MESSAGE();

              EXEC [log].InsertETLBatchEvent 19,@ETLBatchId,NULL,@EventDescription;

              IF @FailBatchOnFailureInd = 1
                THROW; --The error will be logged by ctl.ExecuteETLBatch
              ELSE
                EXEC [ctl].[InsertUnhandledError] @ETLBatchId,@EventDescription;

          END CATCH

          FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand, @SQLCommandName, @RequiresETLBatchIdParameterInd, @RequiresEndETLBatchExecutionParameterInd, @FailBatchOnFailureInd;
      END

    IF @EndETLBatchExecutionInd = 1
      RETURN;


    CLOSE SQLCommandCursor

    DEALLOCATE SQLCommandCursor

    RETURN 0 
