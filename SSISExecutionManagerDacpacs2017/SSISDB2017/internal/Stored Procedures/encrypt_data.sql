
CREATE PROCEDURE [internal].[encrypt_data]
		@key_name               [internal].[adt_name],
		@certificate_name       [internal].[adt_name],
		@data 	nvarchar(max),
		@encrypted_data nvarchar(max) output
WITH EXECUTE AS 'AllSchemaOwner'
AS
	SET NOCOUNT ON
	DECLARE @sqlString  			nvarchar(1024)
    DECLARE @open_cert_sqlString    nvarchar(1024)
	DECLARE @close_cert_sqlString   nvarchar(1024)
	DECLARE @encryption_algorithm   nvarchar(255)
    DECLARE @return_value        bit
    DECLARE @KEY            varbinary(8000)
    DECLARE @IV             varbinary(8000)
	
		
	SET @encryption_algorithm = 'AES_256'
	
	SET @open_cert_sqlString = 'OPEN SYMMETRIC KEY ' + @key_name 
		+ ' DECRYPTION BY CERTIFICATE ' + @certificate_name
	SET @close_cert_sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
					
	
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
	
	SELECT @KEY = DECRYPTBYKEY([key]), @IV = DECRYPTBYKEY([IV]) 
    FROM [internal].[catalog_encryption_keys]
    WHERE [key_name] = @key_name
                
    IF (@KEY IS NULL)
	BEGIN
		SET @sqlString = 'CREATE CERTIFICATE ' + @certificate_name + ' WITH SUBJECT = ''ISServerCertificate'''

		IF  NOT EXISTS (SELECT [name] FROM [sys].[certificates] WHERE [name] = @certificate_name)
			EXECUTE sp_executesql @sqlString 
		
		SET @sqlString = 'CREATE SYMMETRIC KEY ' + @key_name +' WITH ALGORITHM = ' 
							+ @encryption_algorithm + ' ENCRYPTION BY CERTIFICATE ' + @certificate_name
							
		IF  NOT EXISTS (SELECT [name] FROM [sys].[symmetric_keys] WHERE [name] = @key_name)
			EXECUTE sp_executesql @sqlString 		
		
		EXECUTE sp_executesql @open_cert_sqlString 		
		
		
		EXEC @return_value = 
			[internal].[create_key_information] @encryption_algorithm, @KEY output, @IV output
		IF(@return_value <> 0)
		BEGIN
		    RAISERROR(27249, 16 ,1) WITH NOWAIT
			RETURN 1
		END
		
		INSERT INTO [internal].[catalog_encryption_keys]
		VALUES (@key_name, ENCRYPTBYKEY( KEY_GUID(@key_name), @KEY), ENCRYPTBYKEY( KEY_GUID(@key_name), @IV ))
		
		EXECUTE sp_executesql @close_cert_sqlString 
	END
	 
	EXECUTE sp_executesql @open_cert_sqlString 
	
	SET @encrypted_data = ENCRYPTBYKEY(KEY_GUID(@key_name), @data)

	EXECUTE sp_executesql @close_cert_sqlString   

	
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
