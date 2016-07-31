DECLARE @jobId binary(16);
SELECT @jobId = job_id FROM msdb.dbo.sysjobs WHERE (name = N'SSISExecutionManagerExample1')
IF (@jobId IS NOT NULL)
BEGIN
    EXEC msdb.dbo.sp_delete_job @jobId
END

EXEC msdb.dbo.sp_add_job @job_name=N'SSISExecutionManagerExample1', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT


EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Execute [ctl].[ExecuteETLBatch]', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC	[ctl].[ExecuteETLBatch]
			@CallingJobName = N''SSISExecutionManagerExample1'',
			@SSISEnvironmentName = N''SSISExecutionManagerExample1'',
			@ETLBatchId = 1;'
	, 
		@database_name=N'SSISExecutionManager', 
		@flags=0

EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'$(SSISServerName)'


