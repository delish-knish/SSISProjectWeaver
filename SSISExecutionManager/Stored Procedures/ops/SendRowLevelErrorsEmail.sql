CREATE PROCEDURE [ops].[SendRowLevelErrorsEmail]
													@EmailSubject       NVARCHAR(MAX),
                                                    @TimeIntervalInHours TINYINT = 24, 
													@ETLBatchExecutionId INT = NULL
AS
	DECLARE @EmailRecipients VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Email Recipients - Monitors') );


    DECLARE @tableHTML NVARCHAR(MAX)

    SET @tableHTML = N'<H1>Row-level Errors Logged ' + IIF(@ETLBatchExecutionId IS NOT NULL, 'for Batch Execution ' + CAST(@ETLBatchExecutionId AS VARCHAR(10)), 'in Past ' + CAST(@TimeIntervalInHours AS VARCHAR) + ' Hours') + '</H1>'
                     + N'<table border="1">'
                     + N'<tr>
							<th>Process</th>
							<th>Row Key</th>
							<th>Lookup Table</th>
							<th>Lookup Key</th>
							<th>Description</th>
							<th>Date/Time</th>'
                     + CAST ( ( SELECT 
									td = ParentProcessName, '', 
									td = RowKey, '', 
									td = LookupTable, '', 
									td = LookupKey, '', 
									td = [Description], '', 
									td = ErrorDateTime, '' 
								FROM ( 
								
									SELECT 
											ISNULL(err.ParentProcessName, '')	AS ParentProcessName, 
											ISNULL(err.TableProcessRowKey, '')	AS RowKey,
											ISNULL(err.LookupTableName, '')		AS LookupTable,
											ISNULL(err.LookupTableRowKey, '')	AS LookupKey, 
											ISNULL(err.ErrorDateTime, '')		AS ErrorDateTime,
											ISNULL(err.[Description], '')		AS [Description]
									FROM 
										[log].[ETLPackageExecutionRowLevelError] err
										LEFT JOIN [ctl].[ETLBatchSSISDBExecutions] ex ON err.SSISDBExecutionId = ex.SSISDBExecutionId --older versions didn't write the execution id to the row level error table, hence the left join
									WHERE 
										(err.ErrorDateTime BETWEEN DATEADD(hour, -@TimeIntervalInHours, GETDATE()) AND GETDATE() OR @TimeIntervalInHours IS NULL) 
										AND ( ex.ETLBatchExecutionId = @ETLBatchExecutionId OR @ETLBatchExecutionId IS NULL)
										) t 
								FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) )
                     + N'</table>';

    EXEC msdb.dbo.sp_send_dbmail
      @recipients = @EmailRecipients,
      @subject = @EmailSubject,
      @body = @tableHTML,
      @body_format = 'HTML',
      @importance = 'High';

    RETURN 0
