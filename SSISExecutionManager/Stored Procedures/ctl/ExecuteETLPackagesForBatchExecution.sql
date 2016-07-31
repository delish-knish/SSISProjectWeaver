CREATE PROCEDURE [ctl].[ExecuteETLPackagesForBatchExecution] @ETLBatchExecutionId INT,
                                                    --@Periodicity         CHAR(2),
                                                    @SSISEnvironmentName VARCHAR(128)
AS
    --Get list of packages to execute for cursor
    DECLARE @ETLPackageId     INT,
            @EventDescription VARCHAR(MAX);

    DECLARE PackageCursor CURSOR FAST_FORWARD FOR
      SELECT
        ETLPackageId
      FROM
        dbo.func_GetETLPackagesToExecute(@ETLBatchExecutionId) t

    OPEN PackageCursor

    FETCH NEXT FROM PackageCursor INTO @ETLPackageId

    WHILE @@FETCH_STATUS = 0
      BEGIN
          --Determine if SQL Command-based triggers are met
          DECLARE @SQLCommand     NVARCHAR(MAX),
                  @SQLCommandName VARCHAR(128);

          DECLARE @TriggersMetInd BIT = 1;

          DECLARE SQLCommandCursor CURSOR FAST_FORWARD FOR
            SELECT
              SQLCommand + ' @TriggerMetInd OUTPUT'
              ,SQLCommandName
            FROM
              ctl.[ETLPackage_SQLCommandTrigger] b
              JOIN ctl.SQLCommand sc
                ON b.SQLCommandId = sc.SQLCommandId
            WHERE
              ETLPackageId = @ETLPackageId
              AND b.EnabledInd = 1;

          OPEN SQLCommandCursor

          FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand, @SQLCommandName

          WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @ParamDefinition NVARCHAR(MAX) = N'@TriggerMetInd BIT OUTPUT';

                EXECUTE sp_executesql @SQLCommand,@ParamDefinition,@TriggerMetInd = @TriggersMetInd OUT;

                IF @TriggersMetInd = 0
                  BEGIN
                      --Log the failed trigger
                      SET @EventDescription = @SQLCommandName + ' trigger condition not met.';

                      EXEC [log].InsertETLBatchEvent 18,@ETLBatchExecutionId,@ETLPackageId,@EventDescription;

                      BREAK;
                  END
                ELSE
                  BEGIN
                      --Log the trigger success condition
                      SET @EventDescription = @SQLCommandName + ' trigger condition met.';

                      EXEC [log].InsertETLBatchEvent 18,@ETLBatchExecutionId,@ETLPackageId,@EventDescription;
                  END

                FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand, @SQLCommandName
            END

          CLOSE SQLCommandCursor

          DEALLOCATE SQLCommandCursor

          IF @TriggersMetInd = 1 --Execute package
            BEGIN
                DECLARE @SSISExecutionId BIGINT;

                --Log and execute the package
                SET @EventDescription = 'Executing package Id ' + CAST(@ETLPackageId AS VARCHAR(10));

                EXEC [log].InsertETLBatchEvent 3,@ETLBatchExecutionId,@ETLPackageId,@EventDescription;

                EXEC [ctl].ExecuteETLPackage @ETLBatchExecutionId,@ETLPackageId,@SSISEnvironmentName,@SSISExecutionId OUT
            END

          FETCH NEXT FROM PackageCursor INTO @ETLPackageId
      END

    CLOSE PackageCursor

    DEALLOCATE PackageCursor

    RETURN 0 
