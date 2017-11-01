CREATE PROCEDURE [ctl].[ExecuteETLPackagesForBatchExecution] @ETLBatchExecutionId INT,
                                                             @SSISEnvironmentName VARCHAR(128)
AS
    --Get list of packages to execute for cursor
    DECLARE @ETLPackageGroup_ETLPackageId INT
            ,@SSISDBProjectName           NVARCHAR (128)
            ,@ETLPackageGroupId           INT
            ,@ETLPackageGroup             VARCHAR(50)
            ,@ETLPackageId                INT
            ,@SSISDBPackageName           NVARCHAR(260)
            ,@EventDescription            VARCHAR(MAX)
            ,@EmailRecipients             VARCHAR(MAX)
            ,@CRLF                        NVARCHAR(MAX) = CHAR(13) + CHAR(10)
            ,@MailBody                    NVARCHAR(MAX)
            ,@ServerName                  NVARCHAR(MAX) = @@SERVERNAME;
    DECLARE PackageCursor CURSOR FAST_FORWARD FOR
      SELECT
        ETLPackageGroup_ETLPackageId
        ,SSISDBProjectName
        ,ETLPackageGroupId
        ,ETLPackageGroup
        ,ETLPackageId
        ,SSISDBPackageName
      FROM
        dbo.func_GetETLPackagesToExecute(@ETLBatchExecutionId) t

    OPEN PackageCursor

    FETCH NEXT FROM PackageCursor INTO @ETLPackageGroup_ETLPackageId
                                       ,@SSISDBProjectName
                                       ,@ETLPackageGroupId
                                       ,@ETLPackageGroup
                                       ,@ETLPackageId
                                       ,@SSISDBPackageName

    WHILE @@FETCH_STATUS = 0
      BEGIN
          --Determine if SQL Command-based Conditons are met
          DECLARE @SQLCommand                               NVARCHAR(MAX)
                  ,@SQLCommandName                          VARCHAR(128)
                  ,@NotificationOnConditionMetEnabledInd    BIT
                  ,@NotificationOnConditionNotMetEnabledInd BIT
                  ,@NotificationEmailConfigurationCd        VARCHAR(50);
          DECLARE @ConditionsMetInd BIT = 1;
          DECLARE SQLCommandCursor CURSOR FAST_FORWARD FOR
            SELECT
              SQLCommand + ' @ConditionMetInd OUTPUT'
              ,SQLCommandName
              ,b.NotificationOnConditionMetEnabledInd
              ,b.NotificationOnConditionNotMetEnabledInd
              ,b.NotificationEmailConfigurationCd
            FROM
              [cfg].[ETLPackageGroup_ETLPackage_SQLCommandCondition] b
              JOIN [cfg].ETLPackageGroup_ETLPackage epgep
                ON b.ETLPackageGroup_ETLPackageId = epgep.ETLPackageGroup_ETLPackageId
              JOIN [cfg].SQLCommand sc
                ON b.SQLCommandId = sc.SQLCommandId
            WHERE
              epgep.ETLPackageGroup_ETLPackageId = @ETLPackageGroup_ETLPackageId
              AND b.EnabledInd = 1
			  AND epgep.IgnoreSQLCommandConditionsDefaultInd = 0;

          OPEN SQLCommandCursor

          FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand
                                                ,@SQLCommandName
                                                ,@NotificationOnConditionMetEnabledInd
                                                ,@NotificationOnConditionNotMetEnabledInd
                                                ,@NotificationEmailConfigurationCd;

          WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @ParamDefinition NVARCHAR(MAX) = N'@ConditionMetInd BIT OUTPUT';

                SET @EmailRecipients = ( ISNULL([dbo].[func_GetConfigurationValue] (@NotificationEmailConfigurationCd), [dbo].[func_GetConfigurationValue] ('EMAILMON')) );

                EXECUTE sp_executesql
                  @SQLCommand,
                  @ParamDefinition,
                  @ConditionMetInd = @ConditionsMetInd OUT;

                IF @ConditionsMetInd = 0
                  BEGIN
                      --Log the failed condition
                      SET @EventDescription = @SQLCommandName + ' condition not met';

                      EXEC [log].[InsertETLBatchExecutionEvent]
                        18,
                        @ETLBatchExecutionId,
                        @ETLPackageId,
                        @EventDescription;

                      IF @NotificationOnConditionNotMetEnabledInd = 1
                        BEGIN
                            SET @MailBody = N'Project "' + @SSISDBProjectName
                                            + '", Package "' + @SSISDBPackageName
                                            + ', configured for environment "'
                                            + @SSISEnvironmentName
                                            + '" has not met condition "'
                                            + @SQLCommandName + '" on server "'
                                            + @ServerName + '.'

                            EXEC msdb.dbo.sp_send_dbmail
                              @recipients = @EmailRecipients,
                              @subject = 'Package Condition Not Met',
                              @body = @MailBody,
                              @importance = 'High'
                        END

                      BREAK;
                  END
                ELSE
                  BEGIN
                      --Log the success condition
                      SET @EventDescription = @SQLCommandName + ' condition met';

                      EXEC [log].[InsertETLBatchExecutionEvent]
                        18,
                        @ETLBatchExecutionId,
                        @ETLPackageId,
                        @EventDescription;

                      IF @NotificationOnConditionMetEnabledInd = 1
                        BEGIN
                            SET @MailBody = N'Project "' + @SSISDBProjectName
                                            + '", Package "' + @SSISDBPackageName
                                            + ', configured for environment "'
                                            + @SSISEnvironmentName
                                            + '" has met condition "' + @SQLCommandName
                                            + '" on server "' + @ServerName + '.'

                            EXEC msdb.dbo.sp_send_dbmail
                              @recipients = @EmailRecipients,
                              @subject = 'Package Condition Met',
                              @body = @MailBody,
                              @importance = 'High'
                        END
                  END

                FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand
                                                      ,@SQLCommandName
                                                      ,@NotificationOnConditionMetEnabledInd
                                                      ,@NotificationOnConditionNotMetEnabledInd
                                                      ,@NotificationEmailConfigurationCd;
            END

          CLOSE SQLCommandCursor

          DEALLOCATE SQLCommandCursor

          IF @ConditionsMetInd = 1 --Execute package
            BEGIN
                DECLARE @SSISExecutionId BIGINT;

                --Execute and log the package                
                EXEC [ctl].ExecuteETLPackage
                  @ETLBatchExecutionId,
                  @ETLPackageId,
                  @ETLPackageGroupId,
                  @SSISEnvironmentName,
                  @SSISExecutionId OUT

                SET @EventDescription = 'Executing package Id '
                                        + CAST(@ETLPackageId AS VARCHAR(10));

                EXEC [log].[InsertETLBatchExecutionEvent]
                  3,
                  @ETLBatchExecutionId,
                  @ETLPackageId,
                  @EventDescription;

            END

          FETCH NEXT FROM PackageCursor INTO @ETLPackageGroup_ETLPackageId
                                             ,@SSISDBProjectName
                                             ,@ETLPackageGroupId
                                             ,@ETLPackageGroup
                                             ,@ETLPackageId
                                             ,@SSISDBPackageName
      END

    CLOSE PackageCursor

    DEALLOCATE PackageCursor

    RETURN 0 
