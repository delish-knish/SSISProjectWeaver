
CREATE VIEW [catalog].[worker_agent_perfcounter]
AS
	SELECT [WorkerAgentId], [PerfCounterName], [PerfCounterValue], [TimeStamp]
	FROM [internal].[worker_agent_perfcounter]
	Where ((IS_MEMBER('ssis_admin') = 1) OR (IS_SRVROLEMEMBER('sysadmin') = 1) OR (IS_MEMBER('ssis_cluster_executor') = 1))
