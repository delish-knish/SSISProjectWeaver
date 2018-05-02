CREATE PROCEDURE [ops].[SendAndLogLongRunningETLPackageNotification] @EmailRecipientsOverride               VARCHAR(MAX) = NULL,
                                                                     @DaysToIncludeInAverageDuration        SMALLINT = 60,
                                                                     @MinPackageExecutionsRequired          SMALLINT = 5,
                                                                     @MinPackageExecutionDurationToConsider SMALLINT = 20,
                                                                     @PctGreaterThanAverageToInclude        TINYINT = 25
AS
    --Get values from Config table
    DECLARE @EmailRecipients VARCHAR(MAX) = ( ISNULL(@EmailRecipientsOverride, [dbo].[func_GetConfigurationValue] ('Email Recipients - Monitors')) );
    --------------------------------------
    --Declare variables
    --------------------------------------
    DECLARE @SSISDBExecutionId     INT
            ,@SSISDBPackageName    NVARCHAR(4000)
            ,@StartTime            DATETIME
            ,@AverageExecutionTime INT
            ,@EMailBody            VARCHAR(4000)
            ,@CRLF                 CHAR(2) = CHAR(13) + CHAR(10)
            ,@ETLPackageRunTime    INT

  BEGIN
      ---------------------------------------------------------------------------------
      --Check for long running packages.
      ---------------------------------------------------------------------------------
      DECLARE MY_CURSOR CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY FOR
        SELECT
          e.execution_id
          ,p.SSISDBPackageName
          ,e.start_time
          ,DATEDIFF(minute, e.start_time, isnull(e.end_time, SYSDATETIMEOFFSET())) ExecutionDurationInMinutes
          ,avgx.AvgExecutionDurationInMinutes
        --,fx.ETLPackageGroupId
        --,fx.ETLPackageId
        --,DATEDIFF(MINUTE, e.start_time, e.end_time) AS ExecutionDurationInMinutes
        --,avgx.AvgExecutionDurationWithBufferInMinutes
        FROM
          ctl.ETLBatchSSISDBExecutions fx
          JOIN [$(SSISDB)].[catalog].[executions] e
            ON fx.SSISDBExecutionId = e.execution_id
          JOIN cfg.ETLPackage p
            ON fx.ETLPackageId = p.ETLPackageId
          LEFT JOIN [log].ETLPackageExecutionLongRunning epelr
                 ON e.execution_id = epelr.SSISDBExecutionId
          JOIN (SELECT
                  [ETLPackageGroupId]
                  ,[ETLPackageId]
                  ,MIN(StartDateTime)                                                                                                                                      AS MinStartDateTime
                  ,MAX(StartDateTime)                                                                                                                                      AS MaxStartDateTime
                  ,COUNT(*)                                                                                                                                                AS PackageExecutionCount
                  ,AVG([ExecutionDurationInMinutes])                                                                                                                       AS AvgExecutionDurationInMinutes
                  ,CAST(AVG(CAST([ExecutionDurationInMinutes] AS DECIMAL)) * ( CAST(( 100 + @PctGreaterThanAverageToInclude ) AS DECIMAL) / CAST(100 AS DECIMAL) ) AS INT) AS AvgExecutionDurationWithBufferInMinutes
                FROM
                  [log].[ETLPackageExecutionHistory]
                WHERE
                 [ETLPackageExecutionStatusId] = 0
                 AND DATEDIFF(DAY, StartDateTime, GETDATE()) <= @DaysToIncludeInAverageDuration
                GROUP  BY
                 [ETLPackageGroupId]
                 ,[ETLPackageId]
                HAVING
                 COUNT(*) >= @MinPackageExecutionsRequired) avgx
            ON ( fx.[ETLPackageId] = avgx.[ETLPackageId]
                 AND ( fx.[ETLPackageGroupId] = avgx.[ETLPackageGroupId]
                        OR avgx.[ETLPackageGroupId] IS NULL ) )
        WHERE
          e.[status] IN ( 2, 5, 8 ) --Running, Pending, Stopping
          AND epelr.SSISDBExecutionId IS NULL
          AND DATEDIFF(minute, e.start_time, isnull(e.end_time, SYSDATETIMEOFFSET())) >= @MinPackageExecutionDurationToConsider
          AND DATEDIFF(MINUTE, e.start_time, e.end_time) > avgx.AvgExecutionDurationWithBufferInMinutes

      OPEN MY_CURSOR

      FETCH NEXT FROM MY_CURSOR INTO @SSISDBExecutionId
                                     ,@SSISDBPackageName
                                     ,@StartTime
                                     ,@ETLPackageRunTime
                                     ,@AverageExecutionTime

      WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT
              @EMailBody = @@SERVERNAME + @CRLF + N'Severity Level=2'
                           + @CRLF + @SSISDBPackageName
                           + ' has been running for '
                           + CONVERT(VARCHAR(4000), @ETLPackageRunTime)
                           + ' minutes.  The average execution time is '
                           + CONVERT(VARCHAR(4000), @AverageExecutionTime)
                           + ' minutes.  The execution event started at '
                           + CONVERT(VARCHAR(30), @StartTime) + '.'

            --EXEC msdb.dbo.sp_send_dbmail
            --  @recipients = @EmailRecipients,
            --  @subject = 'Slow Running SSIS Package',
            --  @body = @EMailBody

            INSERT INTO [log].ETLPackageExecutionLongRunning
                        (SSISDBExecutionId
                         ,ExecutionStartTime
                         ,AverageExecutionTimeMinutes
                         ,CurrentExectionTimeMinutes)
            VALUES      (@SSISDBExecutionId
                         ,CONVERT(DATETIME, @StartTime, 121)
                         ,@AverageExecutionTime
                         ,@ETLPackageRunTime)

            FETCH NEXT FROM MY_CURSOR INTO @SSISDBExecutionId
                                           ,@SSISDBPackageName
                                           ,@StartTime
                                           ,@ETLPackageRunTime
                                           ,@AverageExecutionTime
        END

      CLOSE MY_CURSOR

      DEALLOCATE MY_CURSOR
  END

    RETURN 0 
