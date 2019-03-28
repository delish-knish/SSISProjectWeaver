
CREATE VIEW [catalog].[alwayson_replicas] 
AS
SELECT		[server_name],
			[state]
FROM		[internal].[alwayson_support_state]
