CREATE FUNCTION [dbo].[func_IsSQLAgentJobRunning] (@JobName NVARCHAR (1000))
RETURNS BIT
AS
  BEGIN
      DECLARE @SQLAgentJobRunningInd BIT = 0;

      IF EXISTS(SELECT
                  job.[name]
                FROM
                  msdb.dbo.sysjobs_view job
                  JOIN msdb.dbo.sysjobactivity activity
                    ON job.job_id = activity.job_id
                  JOIN msdb.dbo.syssessions sess
                    ON sess.session_id = activity.session_id
                  JOIN (SELECT
                          MAX(agent_start_date) AS max_agent_start_date
                        FROM
                          msdb.dbo.syssessions) sess_max
                    ON sess.agent_start_date = sess_max.max_agent_start_date
                WHERE
                 job.[name] = @JobName
                 AND run_requested_date IS NOT NULL
                 AND stop_execution_date IS NULL)
        BEGIN
            SET @SQLAgentJobRunningInd = 1
        END
      ELSE
        SET @SQLAgentJobRunningInd = 0

      RETURN @SQLAgentJobRunningInd;

  END 
