CREATE PROCEDURE [ctl].[RestartETLPackagesForETLBatchExecution] @ETLBatchId           INT,
                                                       @ErrorEmailRecipients VARCHAR(MAX)
AS
    /*This stored procedure will set the ReadyForExecutionInd flag on any package in the given batch that has ended unexpectedly	*/
    DECLARE @ETLPackageId        INT,
            @SSISDBFolderName    VARCHAR(128),
            @SSISDBProjectName   VARCHAR(128),
            @SSISDBPackageName   VARCHAR(260),
            @SSISDBExecutionId   BIGINT,
            @SSISEnvironmentName NVARCHAR(MAX)
    DECLARE UnexpectedErrorCursor CURSOR FAST_FORWARD FOR
      SELECT
        ep.ETLPackageId
        ,SSISDBFolderName
        ,SSISDBProjectName
        ,SSISDBPackageName
        ,SSISDBExecutionId
      FROM
        log.ETLPackageExecutionError e
        JOIN ctl.ETLPackage ep
          ON e.ETLPackageId = ep.ETLPackageId
      WHERE
        e.ETLPackageExecutionErrorTypeId = 2 --unexpected termination
        AND e.ETLPackageRestartDateTime IS NULL
		AND e.[ETLBatchExecutionId] = @ETLBatchId

    OPEN UnexpectedErrorCursor

    FETCH NEXT FROM UnexpectedErrorCursor INTO @ETLPackageId, @SSISDBFolderName, @SSISDBProjectName, @SSISDBPackageName, @SSISDBExecutionId;

    WHILE @@FETCH_STATUS = 0
      BEGIN
            BEGIN
                EXEC sup.RestartPackageForETLBatch @SSISDBFolderName,@SSISDBProjectName,@SSISDBPackageName,0,0

                DECLARE @EventDescription VARCHAR(MAX) = 'Restarting package after unexpected termination';

                EXEC [log].InsertETLBatchEvent 13,@ETLBatchId,@ETLPackageId,@EventDescription;

                --Set the restart/reflag time 
                UPDATE [log].ETLPackageExecutionError
                SET    [ETLPackageRestartDateTime] = GETDATE()
                WHERE
                  ETLPackageExecutionErrorTypeId = 2 --unexpected termination
                  AND [ETLBatchExecutionId] = @ETLBatchId
                  AND ETLPackageId = @ETLPackageId
                  AND [SSISDBExecutionId] = @SSISDBExecutionId;

                --Send email that the package has been flagged for restart
                DECLARE @CRLF             NVARCHAR(MAX) = CHAR(13) + CHAR(10),
                        @MailBody         NVARCHAR(MAX),
                        @ServerName       NVARCHAR(MAX) = @@SERVERNAME
                        
                SELECT
                  @MailBody = N'Project "' + @SSISDBProjectName + '", Package "' + @SSISDBPackageName + ', configured for environment "' + @SSISEnvironmentName + '" has been flagged for restart on server "' + @ServerName + '.'

                EXEC msdb.dbo.sp_send_dbmail @recipients = @ErrorEmailRecipients,@subject = 'Packaged Flagged for Restart',@body = @MailBody,@importance = 'High'
            END

          FETCH NEXT FROM UnexpectedErrorCursor INTO @ETLPackageId, @SSISDBFolderName, @SSISDBProjectName, @SSISDBPackageName, @SSISDBExecutionId;
      END

    CLOSE UnexpectedErrorCursor

    DEALLOCATE UnexpectedErrorCursor

    RETURN 0 
