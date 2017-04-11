CREATE PROCEDURE [ctl].[ExecuteETLPackagesForBatchExecution] @ETLBatchExecutionId INT,
                                                             @SSISEnvironmentName VARCHAR(128)
AS
    --Get list of packages to execute for cursor
    DECLARE @ETLBatchId        INT
            ,@ETLPackageId     INT
            ,@EventDescription VARCHAR(MAX);
    DECLARE PackageCursor CURSOR FAST_FORWARD FOR
      SELECT
        ETLBatchId
       ,ETLPackageId
      FROM
        dbo.func_GetETLPackagesToExecute(@ETLBatchExecutionId) t

    OPEN PackageCursor

    FETCH NEXT FROM PackageCursor INTO @ETLBatchId, @ETLPackageId

    WHILE @@FETCH_STATUS = 0
      BEGIN
          --Determine if SQL Command-based Conditons are met
          DECLARE @SQLCommand      NVARCHAR(MAX)
                  ,@SQLCommandName VARCHAR(128);
          DECLARE @ConditionsMetInd BIT = 1;
          DECLARE SQLCommandCursor CURSOR FAST_FORWARD FOR
            SELECT
              SQLCommand + ' @ConditionMetInd OUTPUT'
             ,SQLCommandName
            FROM
              ctl.[ETLBatch_ETLPackage_SQLCommandCondition] b
              JOIN ctl.SQLCommand sc
                ON b.SQLCommandId = sc.SQLCommandId
            WHERE
              ETLBatchId = @ETLBatchId
              AND ETLPackageId = @ETLPackageId
              AND b.EnabledInd = 1;

          OPEN SQLCommandCursor

          FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand, @SQLCommandName

          WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @ParamDefinition NVARCHAR(MAX) = N'@ConditionMetInd BIT OUTPUT';

                EXECUTE sp_executesql
                  @SQLCommand
                 ,@ParamDefinition
                 ,@ConditionMetInd = @ConditionsMetInd OUT;

                IF @ConditionsMetInd = 0
                  BEGIN
                      --Log the failed condition
                      SET @EventDescription = @SQLCommandName + ' condition not met';

                      EXEC [log].InsertETLBatchEvent
                        18
                       ,@ETLBatchExecutionId
                       ,@ETLPackageId
                       ,@EventDescription;

                      BREAK;
                  END
                ELSE
                  BEGIN
                      --Log the success condition
                      SET @EventDescription = @SQLCommandName + ' condition met';

                      EXEC [log].InsertETLBatchEvent
                        18
                       ,@ETLBatchExecutionId
                       ,@ETLPackageId
                       ,@EventDescription;
                  END

                FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand, @SQLCommandName
            END

          CLOSE SQLCommandCursor

          DEALLOCATE SQLCommandCursor

          IF @ConditionsMetInd = 1 --Execute package
            BEGIN
                DECLARE @SSISExecutionId BIGINT;

                --Log and execute the package
                SET @EventDescription = 'Executing package Id ' + CAST(@ETLPackageId AS VARCHAR(10));

                EXEC [log].InsertETLBatchEvent
                  3
                 ,@ETLBatchExecutionId
                 ,@ETLPackageId
                 ,@EventDescription;

                EXEC [ctl].ExecuteETLPackage
                  @ETLBatchExecutionId
                 ,@ETLPackageId
                 ,@SSISEnvironmentName
                 ,@SSISExecutionId OUT
            END

          FETCH NEXT FROM PackageCursor INTO @ETLBatchId, @ETLPackageId
      END

    CLOSE PackageCursor

    DEALLOCATE PackageCursor

    RETURN 0 
