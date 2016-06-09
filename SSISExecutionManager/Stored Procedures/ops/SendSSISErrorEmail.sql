CREATE PROCEDURE [ops].[SendSSISErrorsEmail] @EmailBodyHeader     NVARCHAR(MAX),
                                             @EmailSubject        NVARCHAR(MAX),
                                             @ExecutionId         BIGINT,
                                             @TimeIntervalInHours TINYINT
AS
    --Get values from Config table
    DECLARE @EmailRecipients VARCHAR(MAX) = ( [dbo].[func_GetConfigurationValue] ('Email Recipients - Monitors') );

    DECLARE @ErrorCount INT,
     @HTMLTable NVARCHAR(MAX),
     @EmailBody NVARCHAR(MAX);

    SET @ErrorCount = (SELECT
                         COUNT(*)
                       FROM
                         ops.func_GetSSISPackageExecutionMessages (120, @ExecutionId) pem
                       WHERE
                        ( pem.message_time BETWEEN DATEADD(hour, -@TimeIntervalInHours, GETDATE()) AND GETDATE()
                           OR @TimeIntervalInHours IS NULL ));


    IF @ErrorCount > 0
      BEGIN
          SET @HTMLTable = N'<p>' + @EmailBodyHeader + '</p>' + N'<table cellspacing="0" style="border: 1px solid black;>' + N'<tr style="border: 1px solid black;>
							   <th style="border: 1px solid black;background-color: yellow;">Id</th>
							   <th style="border: 1px solid black;background-color: yellow;">Project</th>
							   <th style="border: 1px solid black;background-color: yellow;">Package</th>
							   <th style="border: 1px solid black;background-color: yellow;">Error</th>
							   <th style="border: 1px solid black;background-color: yellow;">Date/Time</th>' + CAST ( ( SELECT td = operation_message_id, '', td = [object_name], '', td = package_name, '', td = [message], '', td = message_time, '' FROM ( SELECT pem.operation_message_id, pem.[object_name], pem.package_name, pem.[message], CAST(pem.message_time AS DATETIME2) AS message_time FROM ops.func_GetSSISPackageExecutionMessages (120, @ExecutionId) pem WHERE (pem.message_time BETWEEN DATEADD(hour, -@TimeIntervalInHours, GETDATE()) AND GETDATE() OR @TimeIntervalInHours IS NULL ) ) t ORDER BY operation_message_id FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) + N'</table>';

          SET @HTMLTable = REPLACE(@HTMLTable, '<td>', '<td style="border: 1px solid black;">')

          SET @EmailBody = @HTMLTable
      END
    ELSE
      SET @EmailBody = N'<p>' + @EmailBodyHeader + '</p><b>No error messages available.<b>';


    EXEC msdb.dbo.sp_send_dbmail @recipients = @EmailRecipients,@subject = @EmailSubject,@body = @EmailBody,@body_format = 'HTML',@importance = 'High';

    RETURN 0 
