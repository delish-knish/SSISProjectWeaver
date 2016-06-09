CREATE FUNCTION [dbo].[func_GetSQLAgentJobNextRunDateTime] (@JobName NVARCHAR (1000))
RETURNS DATETIME
AS
  BEGIN
      RETURN
        (SELECT
           MIN(CASE [jobschedule].[next_run_date]
                 WHEN 0 THEN CONVERT(DATETIME, '1900/1/1')
                 ELSE CONVERT(DATETIME, CONVERT(CHAR(8), [jobschedule].[next_run_date], 112) + ' ' + STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), [jobschedule].[next_run_time]), 6), 5, 0, ':'), 3, 0, ':'))
               END) AS NextRunDate
         FROM
           [msdb].[dbo].[sysjobs] AS [jobs] WITH(NOLOCK)
           LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [jobschedule] WITH(NOLOCK)
                  ON [jobs].[job_id] = [jobschedule].[job_id]
         WHERE
          [jobs].[name] = @JobName);
  END 
