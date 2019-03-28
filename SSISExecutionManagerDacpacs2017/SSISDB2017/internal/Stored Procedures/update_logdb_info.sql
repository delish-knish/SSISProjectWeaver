
CREATE PROCEDURE [internal].[update_logdb_info]
		@server_name		nvarchar(max),
		@connection_string 	nvarchar(max)
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON
	DECLARE @encrypted_value  		nvarchar(max)  
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
    DECLARE @return_value           bit
	
	SET @key_name = 'MS_Enckey_LOGDB'
	SET @certificate_name = 'MS_Cert_LOGDB'	
				
	
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
    
    
    
    DECLARE @tran_count INT = @@TRANCOUNT;
    DECLARE @savepoint_name NCHAR(32);
    IF @tran_count > 0
    BEGIN
        SET @savepoint_name = REPLACE(CONVERT(NCHAR(36), NEWID()), N'-', N'');
        SAVE TRANSACTION @savepoint_name;
    END
    ELSE
        BEGIN TRANSACTION;                                                                                       
    BEGIN TRY
	
	EXEC [internal].[encrypt_data]
			@key_name,
			@certificate_name,
			@connection_string,
			@encrypted_value output
	UPDATE [internal].[master_properties]
	SET property_value = @server_name
	WHERE property_name = 'CLUSTER_LOGDB_SERVER'
	
	UPDATE [internal].[master_properties]
	SET property_value = @encrypted_value
	WHERE property_name = 'CLUSTER_LOGDB_CONNECTIONSTRING'  

	
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                             
        THROW 
    END CATCH	
