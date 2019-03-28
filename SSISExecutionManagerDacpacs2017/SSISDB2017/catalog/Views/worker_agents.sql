
CREATE VIEW [catalog].[worker_agents]
AS
	SELECT [WorkerAgentId], [IsEnabled], [DisplayName], [Description], [MachineName], [Tags], [UserAccount], [LastOnlineTime]
	FROM [internal].[worker_agents]
	Where ((IS_MEMBER('ssis_admin') = 1) OR (IS_SRVROLEMEMBER('sysadmin') = 1) OR (IS_MEMBER('ssis_cluster_executor') = 1))
