CREATE PROCEDURE [ops].[SendLongRunningBlockingQueryNotification] @BlockingDurationInMinutes SMALLINT = 1
AS
    --Get values from Config table
    DECLARE @EmailRecipients VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Email Recipients - Monitors') );

    --------------------------------------
    --Declare variables
    --------------------------------------
    DECLARE @Servername        VARCHAR(200),
            @ProgramName       VARCHAR(400),
            @RunningTime       VARCHAR(400),
            @Blocking_SPID     INT,
            @Query_Blocked     VARCHAR(1000),
            @Query_Blocking_it VARCHAR(1000),
            @MailBody          VARCHAR(4000),
            @CRLF              CHAR(2) = CHAR(13) + CHAR(10)



  BEGIN
      ---------------------------------------------------------------------------------
      --Check for long running queries.
      ---------------------------------------------------------------------------------
      DECLARE MY_CURSOR CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY FOR
        SELECT
          host_name                                                                                                                                                                                                                   AS Servername
          ,de.program_name                                                                                                                                                                                                            AS ProgramName
          ,CAST(((DATEDIFF(s, start_time, GETDATE()))/3600) AS VARCHAR) + ' hour(s), ' + CAST((DATEDIFF(s, start_time, GETDATE())%3600)/60 AS VARCHAR) + ' min, ' + CAST((DATEDIFF(s, start_time, GETDATE())%60) AS VARCHAR) + ' sec' AS RunningTime
          ,dr.blocking_session_id                                                                                                                                                                                                     AS Blocking_SPID
          ,dt.text                                                                                                                                                                                                                    AS 'Query_Blocked'
          ,Isnull(a.text, '')                                                                                                                                                                                                         AS 'Query_Blocking_it'
        FROM
          sys.dm_exec_requests dr
          CROSS APPLY sys.dm_exec_sql_text(sql_handle) dt
          INNER JOIN sys.dm_exec_sessions de
                  ON dr.session_id = de.session_id
          LEFT JOIN (SELECT
                       dr.session_id AS SPID
                       ,text
                     FROM
                       sys.dm_exec_requests dr
                       CROSS APPLY sys.dm_exec_sql_text(sql_handle) dt)a
                 ON a.SPID = dr.blocking_session_id
        WHERE
          ( DATEDIFF(s, start_time, GETDATE())%3600 ) / 60 >= @BlockingDurationInMinutes
          AND dr.blocking_session_id > 0
        ORDER  BY
          start_time ASC

      OPEN MY_CURSOR

      FETCH NEXT FROM MY_CURSOR INTO @Servername, @ProgramName, @RunningTime, @Blocking_SPID, @Query_Blocked, @Query_Blocking_it

      WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT
              @MailBody = @@SERVERNAME + @CRLF + 
			N'  ---- > Program Name executing query being blocked: ' + @ProgramName + @CRLF + N'  ---- > Query has been running for ' + @RunningTime + @CRLF
                          + N'  ---- > Blocking Session ID is ' + CAST(@Blocking_SPID AS VARCHAR(100)) + @CRLF + @CRLF + N'  --------------------------------------------------------------' + @CRLF + N'  ---- > SAMPLE TEXT OF QUERY BEING BLOCKED:' + @CRLF + N'  --------------------------------------------------------------' + @CRLF + @CRLF + @Query_Blocked + @CRLF + @CRLF + @CRLF + N'  --------------------------------------------------------------------------' + @CRLF + N'  ---- > SAMPLE TEXT OF QUERY PERFORMING THE BLOCKING: ' + @CRLF
                          + N'  --------------------------------------------------------------------------' + @CRLF + @CRLF + @Query_Blocking_it

            EXEC msdb.dbo.sp_send_dbmail @recipients = @EmailRecipients,@subject = 'Blocking occurring on long running query',@body = @MailBody

            FETCH NEXT FROM MY_CURSOR INTO @Servername, @ProgramName, @RunningTime, @Blocking_SPID, @Query_Blocked, @Query_Blocking_it
        END

      CLOSE MY_CURSOR

      DEALLOCATE MY_CURSOR
  END


    RETURN 0 
