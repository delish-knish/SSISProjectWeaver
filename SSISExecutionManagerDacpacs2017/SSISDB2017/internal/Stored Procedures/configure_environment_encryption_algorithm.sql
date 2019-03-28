CREATE PROCEDURE [internal].[configure_environment_encryption_algorithm]
        @algorithm_name     nvarchar(255),
        @operation_id       bigint
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON
    IF (@algorithm_name IS NULL)
    BEGIN
        RAISERROR(27100, 16, 2, N'algorithm_name') WITH NOWAIT
        RETURN 1;
    END
    
    DECLARE @environment_id bigint
    DECLARE @decrypt_values [internal].[decrypted_data_table]
    
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
    DECLARE @sqlString              nvarchar(1024)
    
    
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

        
        IF EXISTS (SELECT operation_id FROM [internal].[operations]
                WHERE [status] IN (2, 5)
                AND   [operation_id] <> @operation_id )
        BEGIN    
            RAISERROR(27139, 16, 1) WITH NOWAIT
            RETURN 1
        END
        
        
        DECLARE environment_cursor CURSOR LOCAL
            FOR SELECT [environment_id] FROM [internal].[environments]
        OPEN environment_cursor
        
        FETCH NEXT FROM environment_cursor
            INTO @environment_id
        
        
        WHILE (@@FETCH_STATUS = 0)
        BEGIN
            
            DELETE @decrypt_values
            
            
            SET @key_name = 'MS_Enckey_Env_'+CONVERT(varchar(1024),@environment_id)
            SET @certificate_name = 'MS_Cert_Env_'+CONVERT(varchar(1024),@environment_id)
            
            SELECT @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name + ' DECRYPTION BY CERTIFICATE '+ @certificate_name
            EXECUTE sp_executesql @sqlString
    
            
            INSERT @decrypt_values 
            SELECT [variable_id], DECRYPTBYKEY(sensitive_value)            
               FROM [internal].[environment_variables] 
               WHERE [environment_id] = @environment_id
               AND [sensitive] = 1
    
            
            SELECT @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString
        
            
            SELECT @sqlString = 'DROP SYMMETRIC KEY ' + @key_name
            EXECUTE sp_executesql @sqlString
            SELECT @sqlString = 'CREATE SYMMETRIC KEY '+ @key_name + ' WITH ALGORITHM = ' 
                + @algorithm_name + ' ENCRYPTION BY CERTIFICATE ' + @certificate_name
            EXECUTE sp_executesql @sqlString
            
            
            SELECT @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name + ' DECRYPTION BY CERTIFICATE '+ @certificate_name
            EXECUTE sp_executesql @sqlString
            
            
            UPDATE [internal].[environment_variables] 
                SET sensitive_value =  EncryptByKey(KEY_GUID(@key_name),src.value)
                FROM @decrypt_values src
                WHERE variable_id = src.id
            
            
            SELECT @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString
            
            
            FETCH NEXT FROM environment_cursor
                INTO @environment_id            
        END
        CLOSE environment_cursor
        DEALLOCATE environment_cursor
        
        
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        
        
        IF (CURSOR_STATUS('local', 'environment_cursor') = 1 
            OR CURSOR_STATUS('local', 'environment_cursor') = 0)
        BEGIN
            CLOSE environment_cursor
            DEALLOCATE environment_cursor            
        END
        
        
        IF (@key_name <> '')
        BEGIN
            SET @sqlString = 'IF EXISTS (SELECT key_name FROM sys.openkeys WHERE key_name = ''' + @key_name +''') ' 
                  + 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString
        END;
        THROW;
    END CATCH
    RETURN 0
