CREATE PROCEDURE [ctl].[SendErrorNotificationsForETLBatch](@ETLBatchId           INT,
                                                           @ErrorEmailRecipients VARCHAR(MAX))
AS
    DECLARE @SSISDBEventMessageId   BIGINT,
            @SQLAgentJobName        NVARCHAR(MAX),
            @SSISEnvironmentName    NVARCHAR(MAX),
            --@Periodicity                 NVARCHAR(MAX),
            @ETLPackageId           INT,
            @SSISDBFolderName       NVARCHAR(MAX),
            @SSISDBProjectName      NVARCHAR(MAX),
            @SSISDBPackageName      NVARCHAR(MAX),
            @SupportSeverityLevelId NVARCHAR(MAX),
            @SupportSeverityLevelCd NVARCHAR(MAX),
            @ErrorDateTime          DATETIME2,
            @ErrorMessage           NVARCHAR(MAX)

    DECLARE PackageCursor CURSOR FAST_FORWARD FOR
      SELECT
        err.SSISDBEventMessageId
        ,eb.SQLAgentJobName
        ,eb.SSISEnvironmentName
        --,eb.Periodicity
        ,err.ETLPackageId
        ,ep.SSISDBFolderName
        ,ep.SSISDBProjectName
        ,ep.SSISDBPackageName
        ,ep.SupportSeverityLevelId
        ,rssl.SupportSeverityLevelCd
        ,err.ErrorDateTime
        ,err.ErrorMessage
      FROM
        [log].[ETLPackageExecutionError] err
        --Limit errors to the first error per package for the batch 
		--** This logic is flawed when a package is executed multiple times and has failures mutliple times. It will not get the "new" error.
        JOIN (SELECT
                ETLBatchId
                ,ETLPackageId
                ,SSISDBExecutionId
                ,epee.ETLPackageExecutionErrorTypeId
                ,MIN(SSISDBEventMessageId) AS SSISDBEventMessageId
              FROM
                [log].[ETLPackageExecutionError] epee
              WHERE
               EmailNotificationSentDateTime IS NULL
              GROUP  BY
               ETLBatchId
               ,ETLPackageId
               ,epee.ETLPackageExecutionErrorTypeId
               ,SSISDBExecutionId) minerr
          ON err.ETLBatchId = minerr.ETLBatchId
             AND err.ETLPackageId = minerr.ETLPackageId
             AND ( ( err.SSISDBEventMessageId = minerr.SSISDBEventMessageId
                      OR ( err.SSISDBEventMessageId IS NULL
                           AND err.SSISDBExecutionId = minerr.SSISDBExecutionId ) )
                    OR minerr.ETLPackageExecutionErrorTypeId = 3 )
        JOIN ctl.[ETLBatchExecution] eb
          ON err.ETLBatchId = eb.[ETLBatchExecutionId]
        JOIN ctl.ETLPackage ep
          ON err.ETLPackageId = ep.ETLPackageId
        JOIN ref.SupportSeverityLevel rssl
          ON ep.SupportSeverityLevelId = rssl.SupportSeverityLevelId
      WHERE
        eb.[ETLBatchExecutionId] = @ETLBatchId
        AND err.EmailNotificationSentDateTime IS NULL

    OPEN PackageCursor

    FETCH NEXT FROM PackageCursor INTO @SSISDBEventMessageId, @SQLAgentJobName, @SSISEnvironmentName, @ETLPackageId, @SSISDBFolderName, @SSISDBProjectName, @SSISDBPackageName, @SupportSeverityLevelId, @SupportSeverityLevelCd, @ErrorDateTime, @ErrorMessage

    WHILE @@FETCH_STATUS = 0
      BEGIN
          --Send the email
          DECLARE @CRLF             NVARCHAR(MAX) = CHAR(13) + CHAR(10),
                  @MailBody         NVARCHAR(MAX)

          SELECT
            @MailBody = @@SERVERNAME + @CRLF + 
			N'Severity Level=' + @SupportSeverityLevelCd + @CRLF + 
			@SSISDBPackageName + @CRLF + 
			@SSISDBProjectName + '.' + @SSISDBPackageName + ', configured for SSIS Environment [' + @SSISEnvironmentName + '],  under SQL Agent job [' + @SQLAgentJobName + '] failed with error message ["' + @ErrorMessage + '] The error was logged at ' + CAST(CONVERT(VARCHAR(30), @ErrorDateTime) AS NVARCHAR(MAX)) + '.'

          EXEC msdb.dbo.sp_send_dbmail @recipients = @ErrorEmailRecipients,@subject = 'Open Incident',@body = @MailBody,@importance = 'High'

          --Mark the errors as having a notification sent
          UPDATE [log].ETLPackageExecutionError
          SET    EmailNotificationSentDateTime = GETDATE()
          WHERE
            ETLBatchId = @ETLBatchId
            AND ETLPackageId = @ETLPackageId

          FETCH NEXT FROM PackageCursor INTO @SSISDBEventMessageId, @SQLAgentJobName, @SSISEnvironmentName, @ETLPackageId, @SSISDBFolderName, @SSISDBProjectName, @SSISDBPackageName, @SupportSeverityLevelId, @SupportSeverityLevelCd, @ErrorDateTime, @ErrorMessage
      END

    CLOSE PackageCursor

    DEALLOCATE PackageCursor

    RETURN 0 
