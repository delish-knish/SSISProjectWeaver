CREATE PROCEDURE [ops].[SendCompletedBatchExecutionStatistics]
													@ETLBatchExecutionId INT,
													@EmailRecipientsOverride VARCHAR(MAX) = NULL
AS
	DECLARE @EmailRecipients VARCHAR(MAX) = ( ISNULL(@EmailRecipientsOverride,[dbo].[func_GetConfigurationValue] ('Email Recipients - Monitors')) ),
	@InclueDisabledPackages BIT = ( IIF([dbo].[func_GetConfigurationValue] ('Report Disabled Packages') = 'True', 1, 0) ),
    @tableHTML NVARCHAR(MAX),
	@ETLBatchName NVARCHAR(255),
	@ETLBatchStatus NVARCHAR(50),
	@ETLBatchId INT = (SELECT ETLBatchId FROM ctl.ETLBatchExecution WHERE ETLBatchExecutionId = @ETLBatchExecutionId);

	SELECT
		@ETLBatchName = ETLBatchName 
		,@ETLBatchStatus = ETLBatchStatus
	FROM rpt.ETLBatchExecutions 
	WHERE ETLBatchExecutionId = @ETLBatchExecutionId;
	
	DECLARE @DisablePackageCount INT = (SELECT COUNT(*) FROM rpt.ETLPackagesDisabled WHERE ETLBatchId = @ETLBatchId);
	
	DECLARE @EmailSubject VARCHAR(255) = @ETLBatchName + ' ' + @ETLBatchStatus;

    SET @tableHTML = N'<H1>' + 'Batch Id: ' + CAST(@ETLBatchExecutionId AS VARCHAR) + ' - ' + @ETLBatchName + '</H1>'
                     + N'<table cellspacing="0" style="border: 1px solid black;>'
                     + N'<tr style="border: 1px solid black;>
                           <th style="border: 1px solid black;background-color: yellow;">Group</th>
						   <th style="border: 1px solid black;background-color: yellow;">Start</th>
						   <th style="border: 1px solid black;background-color: yellow;">End</th>
						   <th style="border: 1px solid black;background-color: yellow;">Duration</th>
						   <th style="border: 1px solid black;background-color: yellow;">Packages Executed</th>'
                     + CAST ( ( SELECT 
									td = [ETLPackageGroup], '',
									td = StartTime, '', 
									td = EndTime, '' , 
									td = Duration, '', 
									td = [PackagesExecutedNo], ''
								FROM ( 								
									SELECT [ETLPackageGroup],
										   Format([GroupStartDateTime], 'MM/dd/yyyy h:mm tt', 'en-US')     AS StartTime,
										   Format([GroupEndDateTime], 'MM/dd/yyyy h:mm tt', 'en-US')       AS EndTime,
										   IIF(GroupExecutionDurationInMinutes > 59, CONCAT(Cast([GroupExecutionDurationInMinutes] / 60 AS VARCHAR), 'h ', Cast([GroupExecutionDurationInMinutes]%60 AS VARCHAR), 'm'), Concat(Cast([GroupExecutionDurationInMinutes] AS VARCHAR), 'm')) AS Duration,
										   [PackagesExecutedNo],
										   [GroupStartDateTime] AS SortOrder
									FROM   [rpt].[ETLPackageGroupExecutions]
									WHERE  ETLBatchExecutionId = @ETLBatchExecutionId
									UNION ALL
									SELECT 'Total' AS [ETLPackageGroup],
										   Format(Min([GroupStartDateTime]), 'MM/dd/yyyy h:mm tt', 'en-US')                                                                            AS StartTime,
										   Format(Max([GroupEndDateTime]), 'MM/dd/yyyy h:mm tt', 'en-US')                                                                              AS EndTime,
										   Concat(Cast(DATEDIFF(MINUTE,Min([GroupStartDateTime]),MAX([GroupEndDateTime])) / 60 AS VARCHAR), 'h ', Cast(DATEDIFF(MINUTE,Min([GroupStartDateTime]),MAX([GroupEndDateTime]))%60 AS VARCHAR), 'm') AS Duration,
										   Sum([PackagesExecutedNo])                                                                                                                   AS [PackagesExecutedNo],
										   '9999-12-31 11:59:59pm' AS SortOrder
									FROM   [rpt].[ETLPackageGroupExecutions]
									WHERE  [ETLBatchExecutionId] = @ETLBatchExecutionId	 ) t 
									ORDER BY SortOrder
								FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) )
                     + N'</table>';

	IF @InclueDisabledPackages = 1 AND @DisablePackageCount > 0
	BEGIN
		SET @tableHTML = @tableHTML + '<br><br>' + 
			N'<H2>' + ' Disabled Packages (' + CAST(@DisablePackageCount AS NVARCHAR(10)) + ')</H2>'
                     + N'<table cellspacing="0" style="border: 1px solid black;>'
                     + N'<tr style="border: 1px solid black;>
                           <th style="border: 1px solid black;background-color: yellow;">Project Name</th>
						   <th style="border: 1px solid black;background-color: yellow;">Package Name</th>
						   <th style="border: 1px solid black;background-color: yellow;">Comments</th>'
                     + CAST ( ( SELECT 
									td = [SSISDBProjectName], '',
									td = [SSISDBPackageName], '', 
									td = [Comments], '' 
								FROM ( 								
									SELECT [SSISDBProjectName]
										   ,[SSISDBPackageName]
										   ,ISNULL(NULLIF(RTRIM(LTRIM([Comments])),''), '*None Entered*') AS [Comments]
									FROM   [rpt].[ETLPackagesDisabled]
									WHERE  ETLBatchId = @ETLBatchId
									 ) t
								ORDER BY [SSISDBProjectName]
										,[SSISDBPackageName]
								FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) )
                     + N'</table>';
	END

	SET @tableHTML = REPLACE(@tableHTML, '<td>', '<td style="border: 1px solid black;">')

    EXEC msdb.dbo.sp_send_dbmail
      @recipients = @EmailRecipients,
      @subject = @EmailSubject,
      @body = @tableHTML,
      @body_format = 'HTML',
      @importance = 'High';

    RETURN 0