CREATE PROCEDURE [ops].[SendCompletedBatchExecutionStatistics]
													@ETLBatchExecutionId INT
AS
	DECLARE @EmailRecipients VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Email Recipients - Monitors') ),
    @tableHTML NVARCHAR(MAX),
	@ETLBatchName NVARCHAR(255) = (SELECT ETLBatchName FROM rpt.ETLBatchExecutions WHERE ETLBatchExecutionId = @ETLBatchExecutionId);
	
	
	DECLARE @EmailSubject VARCHAR(255) = @ETLBatchName + ' Completed Successfully';

    SET @tableHTML = N'<H1>' + 'Batch Id: ' + CAST(@ETLBatchExecutionId AS VARCHAR) + ' - ' + @ETLBatchName + '</H1>'
                     + N'<table cellspacing="0" style="border: 1px solid black;>'
                     + N'<tr style="border: 1px solid black;>
                           <th style="border: 1px solid black;background-color: yellow;">Phase</th>
						   <th style="border: 1px solid black;background-color: yellow;">Start</th>
						   <th style="border: 1px solid black;background-color: yellow;">End</th>
						   <th style="border: 1px solid black;background-color: yellow;">Duration</th>
						   <th style="border: 1px solid black;background-color: yellow;">Packages Executed</th>'
                     + CAST ( ( SELECT 
									td = [ETLBatchPhase], '',
									td = StartTime, '', 
									td = EndTime, '' , 
									td = Duration, '', 
									td = [PackagesExecutedNo], ''
								FROM ( 								
									SELECT [ETLBatchPhase],
										   Format([PhaseStartDateTime], 'MM/dd/yyyy h:mm tt', 'en-US')     AS StartTime,
										   Format([PhaseEndDateTime], 'MM/dd/yyyy h:mm tt', 'en-US')       AS EndTime,
										   IIF(PhaseExecutionDurationInMinutes > 59, CONCAT(Cast([PhaseExecutionDurationInMinutes] / 60 AS VARCHAR), 'h ', Cast([PhaseExecutionDurationInMinutes]%60 AS VARCHAR), 'm'), Concat(Cast([PhaseExecutionDurationInMinutes] AS VARCHAR), 'm')) AS Duration,
										   [PackagesExecutedNo]
									FROM   [rpt].[ETLBatchPhaseExecutions]
									WHERE  ETLBatchExecutionId = @ETLBatchExecutionId
									UNION ALL
									SELECT 'Total' AS [ETLBatchPhase],
										   Format(Min([PhaseStartDateTime]), 'MM/dd/yyyy h:mm tt', 'en-US')                                                                            AS StartTime,
										   Format(Max([PhaseEndDateTime]), 'MM/dd/yyyy h:mm tt', 'en-US')                                                                              AS EndTime,
										   Concat(Cast(DATEDIFF(MINUTE,Min([PhaseStartDateTime]),MAX([PhaseEndDateTime])) / 60 AS VARCHAR), 'h ', Cast(DATEDIFF(MINUTE,Min([PhaseStartDateTime]),MAX([PhaseEndDateTime]))%60 AS VARCHAR), 'm') AS Duration,
										   Sum([PackagesExecutedNo])                                                                                                                   AS [PackagesExecutedNo]
									FROM   [rpt].[ETLBatchPhaseExecutions]
									WHERE  [ETLBatchExecutionId] = @ETLBatchExecutionId ) t 
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
