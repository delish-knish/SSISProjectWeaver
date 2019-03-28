
CREATE PROCEDURE [internal].[update_operation_status_for_task]
	@status     int, 
    @operation_id bigint,
    @agent_id   UNIQUEIDENTIFIER = NULL
AS
BEGIN
    IF @status = 2 
    BEGIN
        UPDATE [internal].[operations]
        SET [machine_name] = w.[MachineName], [status] = @status, [worker_agent_id] = @agent_id,  [executed_count] = e.[ExecutedCount] 
        FROM (SELECT [MachineName] FROM [internal].[worker_agents]
        WHERE [WorkerAgentId] = @agent_id) w,
        (SELECT  [ExecutedCount] FROM [internal].[tasks] t INNER JOIN [internal].[executions] e ON t.JobId = e.job_id 
        WHERE execution_id = @operation_id) e
        WHERE [operation_id] = @operation_id
    END
    ELSE IF @status in (3, 4, 6, 7, 9)
    BEGIN
        UPDATE [internal].[operations] 
        SET [status] = @status, 
        [end_time] = SYSDATETIMEOFFSET()
        WHERE [operation_id] = @operation_id
    END    
END
