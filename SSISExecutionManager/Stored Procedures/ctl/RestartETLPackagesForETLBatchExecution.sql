CREATE PROCEDURE [ctl].[RestartETLPackagesForETLBatchExecution] @ETLBatchExecutionId           INT,
                                                       @ErrorEmailRecipients VARCHAR(MAX)
AS
    /*This stored procedure will set the ReadyForExecutionInd flag on any package in the given batch that has ended unexpectedly	*/
    DECLARE @ETLPackageId        INT,
            @SSISDBFolderName    NVARCHAR(128),
            @SSISDBProjectName   NVARCHAR(128),
            @SSISDBPackageName   NVARCHAR(260),
            @SSISDBExecutionId   BIGINT,
            @SSISEnvironmentName NVARCHAR(MAX),
			@ETLPackageGroupId   INT
    DECLARE UnexpectedErrorCursor CURSOR FAST_FORWARD FOR
      SELECT
        ep.ETLPackageId
        ,SSISDBFolderName
        ,SSISDBProjectName
        ,SSISDBPackageName
        ,SSISDBExecutionId
		,ETLPackageGroupId
      FROM
        log.ETLPackageExecutionError e
        JOIN [cfg].ETLPackage ep
          ON e.ETLPackageId = ep.ETLPackageId
      WHERE
        e.ETLPackageExecutionErrorTypeId = 2 --unexpected termination
        AND e.ETLPackageRestartDateTime IS NULL
		AND e.[ETLBatchExecutionId] = @ETLBatchExecutionId

    OPEN UnexpectedErrorCursor

    FETCH NEXT FROM UnexpectedErrorCursor INTO @ETLPackageId, @SSISDBFolderName, @SSISDBProjectName, @SSISDBPackageName, @SSISDBExecutionId, @ETLPackageGroupId;

    WHILE @@FETCH_STATUS = 0
      BEGIN
            BEGIN
                EXEC sup.ExecutePackageForETLBatch @ETLBatchExecutionId, @SSISDBFolderName,@SSISDBProjectName,@SSISDBPackageName,@ETLPackageGroupId,@SSISDBExecutionId

                DECLARE @EventDescription VARCHAR(MAX) = 'Restarting package after unexpected termination';

                EXEC [log].[InsertETLBatchExecutionEvent] 13,@ETLBatchExecutionId,@ETLPackageId,@EventDescription;

                --Set the restart/reflag time 
                UPDATE [log].ETLPackageExecutionError
                SET    [ETLPackageRestartDateTime] = GETDATE()
                WHERE
                  ETLPackageExecutionErrorTypeId = 2 --unexpected termination
                  AND [ETLBatchExecutionId] = @ETLBatchExecutionId
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

          FETCH NEXT FROM UnexpectedErrorCursor INTO @ETLPackageId, @SSISDBFolderName, @SSISDBProjectName, @SSISDBPackageName, @SSISDBExecutionId, @ETLPackageGroupId;
      END

    CLOSE UnexpectedErrorCursor

    DEALLOCATE UnexpectedErrorCursor

    RETURN 0 
