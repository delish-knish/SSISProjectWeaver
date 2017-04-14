CREATE PROCEDURE [ctl].[ExecuteETLPackageGroupSQLCommands]	@ETLBatchExecutionId			INT,
															@ETLPackageGroupId				INT,
															@ExecuteAtBeginningOfGroupInd	BIT,
															@ExecuteAtEndOfGroupInd			BIT,
															@EndETLBatchExecutionInd		BIT OUT
AS
    DECLARE @SQLCommand                               NVARCHAR(MAX),
            @SQLCommandName                           VARCHAR(128),
            @RequiresETLBatchIdParameterInd           BIT,
            @RequiresEndETLBatchExecutionParameterInd BIT,
            @FailBatchOnFailureInd                    BIT, --If true then throw exception, else log it and continue
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
        JOIN ctl.[ETLPackageGroup_SQLCommand] ebpsc
          ON sc.SQLCommandId = ebpsc.SQLCommandId
      WHERE
        ebpsc.[ETLPackageGroupId] = @ETLPackageGroupId
        AND (NULLIF(ebpsc.[ExecuteAtBeginningOfGroupInd], 0) = @ExecuteAtBeginningOfGroupInd
				OR NULLIF(ebpsc.[ExecuteAtEndOfGroupInd], 0) = @ExecuteAtEndOfGroupInd)
      ORDER  BY
        ExecutionOrder;

    OPEN SQLCommandCursor

    FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand, @SQLCommandName, @RequiresETLBatchIdParameterInd, @RequiresEndETLBatchExecutionParameterInd, @FailBatchOnFailureInd;

    WHILE @@FETCH_STATUS = 0
      BEGIN
          --Execute the SQL Command
          SET @EventDescription = 'Executing SQL Command "' + @SQLCommandName + '"';

          EXEC [log].[InsertETLBatchExecutionEvent] 15,@ETLBatchExecutionId,NULL,@EventDescription;

          --Use a TRY/CATCH block so that we can continue executing upon failure
          BEGIN TRY
              DECLARE @SQLCommandHasParamsInd BIT = ( IIF(CHARINDEX('@', @SQLCommand) > 0, 1, 0) );

              SET @SQLCommand = @SQLCommand + IIF(@RequiresETLBatchIdParameterInd = 1 AND @SQLCommandHasParamsInd = 1, ',', '') + IIF(@RequiresETLBatchIdParameterInd = 1, '@ETLBatchExecutionId = ' + CAST(@ETLBatchExecutionId AS VARCHAR(10)), '');

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

              EXEC [log].[InsertETLBatchExecutionEvent] 19,@ETLBatchExecutionId,NULL,@EventDescription;

              IF @FailBatchOnFailureInd = 1
                THROW; --The error will be logged by ctl.ExecuteETLBatch
              ELSE
                EXEC [ctl].[InsertUnhandledError] @ETLBatchExecutionId,@EventDescription;

          END CATCH

          FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand, @SQLCommandName, @RequiresETLBatchIdParameterInd, @RequiresEndETLBatchExecutionParameterInd, @FailBatchOnFailureInd;
      END

    IF @EndETLBatchExecutionInd = 1
      RETURN;


    CLOSE SQLCommandCursor

    DEALLOCATE SQLCommandCursor

    RETURN 0 
