CREATE PROCEDURE [ops].[SendLongRunningBlockingQueryNotification] @BlockingDurationInMinutes SMALLINT = 1,
													@EmailRecipientsOverride VARCHAR(MAX) = NULL,
													@WinningLogin VARCHAR(200) = NULL
AS
    --Get values from Config table
    DECLARE @EmailRecipients VARCHAR(MAX) = ( ISNULL(@EmailRecipientsOverride,[dbo].[func_GetConfigurationValue] ('Email Recipients - Monitors')) );

    --------------------------------------
    --Declare variables
    --------------------------------------
    DECLARE @BlockedHostName			NVARCHAR(200),
            @BlockedProgramName			NVARCHAR(400),
            @BlockedLogin				NVARCHAR(400),
            @RunningTime				NVARCHAR(400),
            @BlockingSessionId			INT,
			@BlockingHostName			NVARCHAR(200),
            @BlockingProgramName		NVARCHAR(400),
            @BlockingLogin				NVARCHAR(400),
            @BlockedQuery				NVARCHAR(4000),
            @BlockingQuery				NVARCHAR(4000),
            @MailBody					NVARCHAR(MAX),
            @CRLF						CHAR(2) = CHAR(13) + CHAR(10)



  BEGIN
      ---------------------------------------------------------------------------------
      --Check for long running queries.
      ---------------------------------------------------------------------------------
      DECLARE MY_CURSOR CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY FOR
        SELECT
		  de.host_name							AS BlockedHostName
		  ,de.program_name						AS BlockedProgramName
		  ,de.login_name			            AS BlockedLogin
		  ,CAST(((DATEDIFF(s, start_time, GETDATE()))/3600) AS VARCHAR)
		   + ' hour(s), '
		   + CAST((DATEDIFF(s, start_time, GETDATE())%3600)/60 AS VARCHAR)
		   + ' min, '
		   + CAST((DATEDIFF(s, start_time, GETDATE())%60) AS VARCHAR)
		   + ' sec'								AS RunningTime
		  ,dr.blocking_session_id				AS BlockingSessionId
		  ,ISNULL(blocker.host_name  , '')      AS BlockingHostName
		  ,ISNULL(blocker.program_name , '')    AS BlockingProgramName
		  ,ISNULL(blocker.login_name, '')	    AS BlockingLoginName
		  ,ISNULL(dt.text  , '')                AS BlockedQuery
		  ,Isnull(blocker.text, '')				AS BlockingQuery
		FROM   sys.dm_exec_requests dr
			   CROSS APPLY sys.dm_exec_sql_text(sql_handle) dt
			   INNER JOIN sys.dm_exec_sessions de
					   ON dr.session_id = de.session_id
			   LEFT JOIN (SELECT
							dr.session_id
							,de.host_name
							,de.program_name
							,de.login_name
							,text
						  FROM   sys.dm_exec_requests dr
								 CROSS APPLY sys.dm_exec_sql_text(sql_handle) dt
								 INNER JOIN sys.dm_exec_sessions de
										 ON dr.session_id = de.session_id) blocker
					  ON dr.blocking_session_id = blocker.session_id
		WHERE
		  dr.blocking_session_id > 0
		ORDER  BY
		  start_time ASC 

      OPEN MY_CURSOR

      FETCH NEXT FROM MY_CURSOR INTO    @BlockedHostName, @BlockedProgramName, @BlockedLogin, @RunningTime, @BlockingSessionId, @BlockingHostName, @BlockingProgramName, @BlockingLogin, @BlockedQuery, @BlockingQuery		

      WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT
              @MailBody = N'On Server ' + @@SERVERNAME + @CRLF + 
			  N'--Session causing blocking: ' + CAST(@BlockingSessionId AS NVARCHAR(20)) + @CRLF +
			  N'--Host causing blocking: ' + @BlockingHostName + @CRLF +
			  N'--Program causing blocking: ' + @BlockingProgramName + @CRLF + 
			  N'--Login causing blocking: ' + @BlockingLogin + @CRLF + 
			  N'--Host blocked: ' + @BlockedHostName + @CRLF +
			  N'--Program blocked: ' + @BlockedProgramName + @CRLF + 
			  N'--Login blocked: ' + @BlockedLogin + @CRLF + 
			  N'--Blocked for: ' + @RunningTime + @CRLF + @CRLF + 
			  N'  --------------------------------------------------------------' + @CRLF + 
			  N'  ---- BLOCKED QUERY' + @CRLF + 
			  N'  --------------------------------------------------------------' + @CRLF + @CRLF + 
			  @BlockedQuery + @CRLF + @CRLF + @CRLF + 
			  N'  --------------------------------------------------------------------------' + @CRLF + 
			  N'  ---- BLOCKING QUERY ' + @CRLF +
              N'  --------------------------------------------------------------------------' + @CRLF + @CRLF + 
			  @BlockingQuery + @CRLF + @CRLF +
			  IIF(@WinningLogin = @BlockedLogin AND @BlockingLogin <> @WinningLogin, 'Session ' + CAST(@BlockingSessionId AS NVARCHAR(20)) + ' KILLED!', '');

			  IF @WinningLogin = @BlockedHostName AND @BlockingHostName <> @WinningLogin
			  BEGIN
			    DECLARE @KillSQL NVARCHAR(4000) = 'KILL ' + CAST(@BlockingSessionId AS VARCHAR(100));
				EXEC sp_executesql @KillSQL;
			  END

            EXEC msdb.dbo.sp_send_dbmail @recipients = @EmailRecipients,@subject = 'Blocking occurring on long running query',@body = @MailBody

            FETCH NEXT FROM MY_CURSOR INTO @BlockedHostName, @BlockedProgramName, @BlockedLogin, @RunningTime, @BlockingSessionId, @BlockingHostName, @BlockingProgramName, @BlockingLogin, @BlockedQuery, @BlockingQuery		
        END

      CLOSE MY_CURSOR

      DEALLOCATE MY_CURSOR
  END


    RETURN 0 
