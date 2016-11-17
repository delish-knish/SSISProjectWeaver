CREATE PROCEDURE [ctl].[SendErrorNotificationsForETLBatchExecution](@ETLBatchId           INT,
                                                                    @ErrorEmailRecipients VARCHAR(MAX))
AS
    DECLARE @SSISDBEventMessageId    BIGINT
            ,@CallingJobName         NVARCHAR(MAX)
            ,@SSISEnvironmentName    NVARCHAR(MAX)
            ,@ETLPackageId           INT
            ,@SSISDBFolderName       NVARCHAR(MAX)
            ,@SSISDBProjectName      NVARCHAR(MAX)
            ,@SSISDBPackageName      NVARCHAR(MAX)
            ,@EntryPointPackageName  NVARCHAR(MAX)
            ,@SupportSeverityLevelId NVARCHAR(MAX)
            ,@SupportSeverityLevelCd NVARCHAR(MAX)
            ,@ErrorDateTime          DATETIME2(0)
            ,@ErrorMessage           NVARCHAR(MAX)
            ,@RemainingRetryAttempts INT
    DECLARE PackageCursor CURSOR FAST_FORWARD FOR
      SELECT
        err.SSISDBEventMessageId
       ,eb.[CallingJobName]
       ,eb.SSISEnvironmentName
       ,err.ETLPackageId
       ,ep.SSISDBFolderName
       ,ep.SSISDBProjectName
       ,ep.SSISDBPackageName
       ,ISNULL(epp.SSISDBPackageName, ep.SSISDBPackageName)           AS EntryPointPackageName
       ,ep.SupportSeverityLevelId
       ,rssl.SupportSeverityLevelCd
       ,CAST(err.ErrorDateTime AS DATETIME2(0))                       AS ErrorDateTime
       ,err.ErrorMessage
       ,ISNULL(epp.RemainingRetryAttempts, ep.RemainingRetryAttempts) AS RemainingRetryAttempts
      FROM
        [log].[ETLPackageExecutionError] err
        --Limit errors to the first error per package for the batch 
        --** This logic is flawed when a package is executed multiple times and has failures mutliple times. It will not get the "new" error.
        JOIN (SELECT
                [ETLBatchExecutionId]
               ,ETLPackageId
               ,SSISDBExecutionId
               ,epee.ETLPackageExecutionErrorTypeId
               ,MIN(SSISDBEventMessageId) AS SSISDBEventMessageId
              FROM
                [log].[ETLPackageExecutionError] epee
              WHERE
               EmailNotificationSentDateTime IS NULL
              GROUP  BY
               [ETLBatchExecutionId]
               ,ETLPackageId
               ,epee.ETLPackageExecutionErrorTypeId
               ,SSISDBExecutionId) minerr
          ON err.[ETLBatchExecutionId] = minerr.[ETLBatchExecutionId]
             AND err.ETLPackageId = minerr.ETLPackageId
             AND ((err.SSISDBEventMessageId = minerr.SSISDBEventMessageId
                    OR (err.SSISDBEventMessageId IS NULL
                        AND err.SSISDBExecutionId = minerr.SSISDBExecutionId))
                   OR minerr.ETLPackageExecutionErrorTypeId = 3)
        JOIN ctl.[ETLBatchExecution] eb
          ON err.[ETLBatchExecutionId] = eb.[ETLBatchExecutionId]
        JOIN ctl.ETLPackage ep
          ON err.ETLPackageId = ep.ETLPackageId
        JOIN ref.SupportSeverityLevel rssl
          ON ep.SupportSeverityLevelId = rssl.SupportSeverityLevelId
        LEFT JOIN ctl.ETLPackage epp
               ON ep.EntryPointETLPackageId = epp.ETLPackageId
      WHERE
        eb.[ETLBatchExecutionId] = @ETLBatchId
        AND err.EmailNotificationSentDateTime IS NULL

    OPEN PackageCursor

    FETCH NEXT FROM PackageCursor INTO @SSISDBEventMessageId
                                       ,@CallingJobName
                                       ,@SSISEnvironmentName
                                       ,@ETLPackageId
                                       ,@SSISDBFolderName
                                       ,@SSISDBProjectName
                                       ,@SSISDBPackageName
                                       ,@EntryPointPackageName
                                       ,@SupportSeverityLevelId
                                       ,@SupportSeverityLevelCd
                                       ,@ErrorDateTime
                                       ,@ErrorMessage
                                       ,@RemainingRetryAttempts

    WHILE @@FETCH_STATUS = 0
      BEGIN
          --Send the email
          DECLARE @CRLF      NVARCHAR(MAX) = CHAR(13) + CHAR(10)
                  ,@MailBody NVARCHAR(MAX)

          SELECT
            @MailBody = N'Severity Level: ' + @SupportSeverityLevelCd + @CRLF +
						N'Server: ' + @@SERVERNAME + @CRLF +
						N'Job Name: ' + @CallingJobName + @CRLF +
						N'Project Name: ' + @SSISDBProjectName + @CRLF +
						N'Package Name: ' + @SSISDBPackageName + @CRLF +
						N'Entry-point Package Name: ' + @EntryPointPackageName + @CRLF +
						N'SSIS Environment: ' + @SSISEnvironmentName + @CRLF +
						N'Error Date/Time: ' + CAST(CONVERT(VARCHAR(30), @ErrorDateTime) AS NVARCHAR(MAX)) + @CRLF +
						N'Retry Attempts Remaining: ' + CAST(@RemainingRetryAttempts AS VARCHAR(10)) + @CRLF + @CRLF +
						N'Error Description: ' + @ErrorMessage

          EXEC msdb.dbo.sp_send_dbmail
            @recipients = @ErrorEmailRecipients
           ,@subject = 'Open Incident'
           ,@body = @MailBody
           ,@importance = 'High'

          --Mark the errors as having a notification sent
          UPDATE [log].ETLPackageExecutionError
          SET    EmailNotificationSentDateTime = GETDATE()
          WHERE
            [ETLBatchExecutionId] = @ETLBatchId
            AND ETLPackageId = @ETLPackageId

          FETCH NEXT FROM PackageCursor INTO @SSISDBEventMessageId
                                             ,@CallingJobName
                                             ,@SSISEnvironmentName
                                             ,@ETLPackageId
                                             ,@SSISDBFolderName
                                             ,@SSISDBProjectName
                                             ,@SSISDBPackageName
                                             ,@EntryPointPackageName
                                             ,@SupportSeverityLevelId
                                             ,@SupportSeverityLevelCd
                                             ,@ErrorDateTime
                                             ,@ErrorMessage
                                             ,@RemainingRetryAttempts
      END

    CLOSE PackageCursor

    DEALLOCATE PackageCursor

    RETURN 0 
