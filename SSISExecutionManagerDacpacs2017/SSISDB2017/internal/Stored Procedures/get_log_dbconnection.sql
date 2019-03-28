
CREATE PROCEDURE [internal].[get_log_dbconnection]
		@connection_string 	nvarchar(max) output
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON 
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
	DECLARE @encrypted_value  		nvarchar(max) 
	
	SET @key_name = 'MS_Enckey_LOGDB'
	SET @certificate_name = 'MS_Cert_LOGDB'
	
	SELECT @encrypted_value = [property_value]
	FROM [internal].[master_properties]
	WHERE [property_name] = 'CLUSTER_LOGDB_CONNECTIONSTRING'
	
	EXEC [internal].[decrypt_data]
			@key_name,
			@certificate_name,
			@encrypted_value,
			@connection_string output
