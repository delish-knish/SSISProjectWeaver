CREATE PROCEDURE [ops].[SendRowLevelErrorsEmail]
													@EmailSubject       NVARCHAR(MAX),
                                                    @TimeIntervalInHours TINYINT = 24
AS
	DECLARE @EmailRecipients VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Email Recipients - Monitors') );


    DECLARE @tableHTML NVARCHAR(MAX)

    SET @tableHTML = N'<H1>Row Level Errors Logged in Past ' + CAST(@TimeIntervalInHours AS VARCHAR) + ' Hours </H1>'
                     + N'<table border="1">'
                     + N'<tr>
                           <th>Table</th>'
                       + N'<th>Description</th>
						   <th>Date/Time</th>'
                     + CAST ( ( SELECT 
									td = LookupTableName, '', 
									td = Comment, '', 
									td = ErrorDateTime, '' 
								FROM ( 
								
									SELECT 
											err.LookupTableName, 
											err.ErrorDateTime,
											err.Comment
									FROM 
										[log].[ETLPackageExecutionRowLevelError] err
									WHERE 
										(err.ErrorDateTime BETWEEN DATEADD(hour, -@TimeIntervalInHours, GETDATE()) AND GETDATE() OR @TimeIntervalInHours IS NULL)) t 
								FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) )
                     + N'</table>';

    EXEC msdb.dbo.sp_send_dbmail
      @recipients = @EmailRecipients,
      @subject = @EmailSubject,
      @body = @tableHTML,
      @body_format = 'HTML',
      @importance = 'High';

    RETURN 0
