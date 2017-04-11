CREATE PROCEDURE [ops].[SendETLBatchGroupsStatusesNotification]
													@ETLBatchExecutionId INT,
													@EmailRecipientsOverride VARCHAR(MAX) = NULL
AS
	DECLARE @EmailRecipients VARCHAR(MAX) = ( ISNULL(@EmailRecipientsOverride,[dbo].[func_GetConfigurationValue] ('Email Recipients - Monitors')) ),
    @tableHTML NVARCHAR(MAX),
	@ETLBatchName NVARCHAR(255),
	@ETLBatchStatus NVARCHAR(50);

	SELECT
		@ETLBatchName = ETLBatchName 
		,@ETLBatchStatus = ETLBatchStatus
	FROM rpt.ETLBatchExecutions 
	WHERE ETLBatchExecutionId = @ETLBatchExecutionId;
	
	DECLARE @EmailSubject VARCHAR(255) = 'ETL Batch Status: ' + @ETLBatchName + ' ' + @ETLBatchStatus;

    SET @tableHTML = N'<H1>' + 'Batch Id: ' + CAST(@ETLBatchExecutionId AS VARCHAR) + ' - ' + @ETLBatchName + '</H1>'
                     + N'<table cellspacing="0" style="border: 1px solid black;>'
                     + N'<tr style="border: 1px solid black;>
                           <th style="border: 1px solid black;background-color: gray;">Process/Package Group</th>
						   <th style="border: 1px solid black;background-color: gray;">Start</th>
						   <th style="border: 1px solid black;background-color: gray;">End</th>'
                     + CAST ( ( SELECT 
									td = [ETLPackageGroup], '',
									td = StartTime, '', 
									td = EndTime, ''
								FROM ( 								
									SELECT [ETLPackageGroup],
										   ISNULL(Format([GroupStartDateTime], 'MM/dd/yyyy h:mm tt', 'en-US'), '-')     AS StartTime,
										   ISNULL(Format([GroupEndDateTime], 'MM/dd/yyyy h:mm tt', 'en-US'), '-')       AS EndTime,
										   ISNULL([GroupStartDateTime], '9999-12-31') AS SortOrder
									FROM   [rpt].[ETLBatchGroupsStatuses]
									WHERE  ETLBatchExecutionId = @ETLBatchExecutionId ) t 
									ORDER BY SortOrder
								FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) )
                     + N'</table>';

	SET @tableHTML = REPLACE(@tableHTML, '<td>', '<td style="border: 1px solid black;">')

    EXEC msdb.dbo.sp_send_dbmail
      @recipients = @EmailRecipients,
      @subject = @EmailSubject,
      @body = @tableHTML,
      @body_format = 'HTML',
      @importance = 'High';

    RETURN 0