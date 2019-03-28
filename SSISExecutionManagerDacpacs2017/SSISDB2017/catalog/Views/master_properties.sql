
CREATE VIEW [catalog].[master_properties]
AS
	SELECT [property_name], [property_value]
	FROM [internal].[master_properties]
	WHERE [property_name] <> 'CLUSTER_LOGDB_CONNECTIONSTRING'
