CREATE PROCEDURE [ctl].[AreETLBatchSQLCommandConditionsMet] (@ETLBatchId          INT,
                                                             @ETLBatchExecutionId INT,
                                                             @SSISEnvironmentName VARCHAR(128),
                                                             @ConditionsMetInd    BIT = NULL OUT)
AS
  BEGIN
	  SET NOCOUNT ON;

      --Determine if SQL Command-based Conditons are met
      DECLARE @SQLCommand      NVARCHAR(MAX)
              ,@SQLCommandName VARCHAR(128)
                  ,@NotificationOnConditionMetEnabledInd    BIT
                  ,@NotificationOnConditionNotMetEnabledInd BIT
                  ,@NotificationEmailConfigurationCd        VARCHAR(50)
            ,@EmailRecipients             VARCHAR(MAX)
            ,@CRLF                        NVARCHAR(MAX) = CHAR(13) + CHAR(10)
            ,@MailBody                    NVARCHAR(MAX)
            ,@ServerName                  NVARCHAR(MAX) = @@SERVERNAME;

      SET @ConditionsMetInd = 1;

      DECLARE SQLCommandCursor CURSOR FAST_FORWARD FOR
        SELECT
          SQLCommand + ' @ConditionMetInd OUTPUT'
         ,SQLCommandName
		 ,b.NotificationOnConditionMetEnabledInd
		 ,b.NotificationOnConditionNotMetEnabledInd
		 ,b.NotificationEmailConfigurationCd
        FROM
          [cfg].[ETLBatch_SQLCommandCondition] b
          JOIN [cfg].SQLCommand sc
            ON b.SQLCommandId = sc.SQLCommandId
        WHERE
          ETLBatchId = @ETLBatchId
          AND b.EnabledInd = 1;

      OPEN SQLCommandCursor

      FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand, @SQLCommandName
                                                ,@NotificationOnConditionMetEnabledInd
                                                ,@NotificationOnConditionNotMetEnabledInd
                                                ,@NotificationEmailConfigurationCd;

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

				   IF @NotificationOnConditionNotMetEnabledInd = 1
                        BEGIN
                            SET @MailBody = N'An ETL batch configured for environment "'
                                            + @SSISEnvironmentName
                                            + '" has not met condition "'
                                            + @SQLCommandName + '" on server "'
                                            + @ServerName + '.'

                            EXEC msdb.dbo.sp_send_dbmail
                              @recipients = @EmailRecipients,
                              @subject = 'ETL Batch Condition Not Met',
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
                    18
                   ,@ETLBatchExecutionId
                   ,NULL
                   ,@EventDescription;

				  IF @NotificationOnConditionMetEnabledInd = 1
                        BEGIN
                            SET @MailBody = N'An ETL batch configured for environment "'
                                            + @SSISEnvironmentName
                                            + '" has met condition "'
                                            + @SQLCommandName + '" on server "'
                                            + @ServerName + '.'

                            EXEC msdb.dbo.sp_send_dbmail
                              @recipients = @EmailRecipients,
                              @subject = 'ETL Batch Condition Met',
                              @body = @MailBody,
                              @importance = 'High'
                        END
              END

            FETCH NEXT FROM SQLCommandCursor INTO @SQLCommand, @SQLCommandName
                                                ,@NotificationOnConditionMetEnabledInd
                                                ,@NotificationOnConditionNotMetEnabledInd
                                                ,@NotificationEmailConfigurationCd;
        END

      CLOSE SQLCommandCursor

      DEALLOCATE SQLCommandCursor
  END 
