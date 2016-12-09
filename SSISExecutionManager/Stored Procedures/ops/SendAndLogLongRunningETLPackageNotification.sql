CREATE PROCEDURE [ops].[SendAndLogLongRunningETLPackageNotification] 
AS

	--Get values from Config table
    DECLARE @EmailRecipients           VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Email Recipients - Monitors') );
    --------------------------------------
    --Declare variables
    --------------------------------------
    DECLARE @SSISDBExecutionId    INT,
            @SSISDBPackageName    VARCHAR(4000),
            @StartTime            DATETIME,
            @AverageExecutionTime INT,
            @EMailBody            VARCHAR(4000),
            @CRLF                 CHAR(2) = CHAR(13) + CHAR(10),
            @ETLPackageRunTime    INT,
			@MinimumPackageRunTimeToIncl SMALLINT = 45

  BEGIN
      ---------------------------------------------------------------------------------
      --Check for long running packages.
      ---------------------------------------------------------------------------------
      DECLARE MY_CURSOR CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY FOR
        SELECT
          execution_id
          ,package_name
          ,start_time
          ,Package_Run_Time
          ,Average_Execution_Time_With_Lift / 1.5 Average_Execution_Time
        FROM
          (SELECT
             execution_id
             ,package_name
             ,status
             ,start_time
             ,end_time
             ,DATEDIFF(minute, e.start_time, isnull(e.end_time, SYSDATETIMEOFFSET())) Package_Run_Time
             ,(SELECT
                 ( AVG(iif(a.Max_Execution_time_ch2 < 5, NULL, a.Max_Execution_time_ch2)) * 1.25 ) + 1
               FROM
                 (SELECT
                    CAST(start_time AS DATE)                             AS Max_date_ch
                    ,MAX(DATEDIFF(minute, sub.start_time, sub.end_time)) AS Max_Execution_time_ch2
                  FROM
                    [$(SSISDB)].[catalog].[executions] sub
                  WHERE
                   sub.package_name = e.package_name
                   AND sub.status = 7
                   AND DATEDIFF(minute, CONVERT(TIME, CONVERT(DATETIME2, sub.start_time, 1), 108), (SELECT
                                                                                                      CONVERT(TIME, CONVERT(DATETIME2, start_time, 1), 108)
                                                                                                    FROM
                                                                                                      [$(SSISDB)].[catalog].[executions]
                                                                                                    WHERE
                                                                                                     execution_id = e.execution_id)) BETWEEN -180 AND 180
                  GROUP  BY
                   CAST(start_time AS DATE))a)                                        Average_Execution_Time_With_Lift
           FROM
             [$(SSISDB)].[catalog].[executions] e WITH (NOLOCK)
           WHERE
            status NOT IN ( 1, 3, 4, 6,
                            7, 9 )
            AND execution_id NOT IN (SELECT
                                       epelr.SSISDBExecutionId
                                     FROM
                                       [log].ETLPackageExecutionLongRunning epelr)) a
        WHERE
          ( package_run_time > Average_Execution_Time_With_Lift )
          AND ( package_run_time > @MinimumPackageRunTimeToIncl )

      OPEN MY_CURSOR

      FETCH NEXT FROM MY_CURSOR INTO @SSISDBExecutionId, @SSISDBPackageName, @StartTime, @ETLPackageRunTime, @AverageExecutionTime

      WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT
              @EMailBody = @@SERVERNAME + @CRLF +
					N'Severity Level=2' + @CRLF +
					@SSISDBPackageName + ' has been running for ' + CONVERT(VARCHAR(4000), @ETLPackageRunTime) + ' minutes.  The average execution time is ' + CONVERT(VARCHAR(4000), @AverageExecutionTime) + ' minutes.  The execution event started at ' + CONVERT(VARCHAR(30), @StartTime) + '.'

            EXEC msdb.dbo.sp_send_dbmail @recipients = @EmailRecipients,@subject = 'Slow Running SSIS Package',@body = @EMailBody

            INSERT INTO [log].ETLPackageExecutionLongRunning
                        (SSISDBExecutionId
                         ,ExecutionStartTime
						 ,AverageExecutionTimeMinutes
						 ,CurrentExectionTimeMinutes)
            VALUES      (@SSISDBExecutionId
                         ,CONVERT(DATETIME, @StartTime, 121)
						 ,@AverageExecutionTime
						 ,@ETLPackageRunTime)

            FETCH NEXT FROM MY_CURSOR INTO @SSISDBExecutionId, @SSISDBPackageName, @StartTime, @ETLPackageRunTime, @AverageExecutionTime
        END

      CLOSE MY_CURSOR

      DEALLOCATE MY_CURSOR
  END

    RETURN 0 
