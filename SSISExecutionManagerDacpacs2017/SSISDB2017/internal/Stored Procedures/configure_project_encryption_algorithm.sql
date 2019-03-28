CREATE PROCEDURE [internal].[configure_project_encryption_algorithm]
        @algorithm_name     nvarchar(255),
        @old_algorithm_name  nvarchar(255),
        @operation_id       bigint
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON
    IF (@algorithm_name IS NULL)
    BEGIN
        RAISERROR(27100, 16, 2, N'algorithm_name') WITH NOWAIT
        RETURN 1;
    END
    
    DECLARE @project_id bigint
    DECLARE @decrypt_parameter_values [internal].[decrypted_data_table]
    DECLARE @decrypt_project_values [internal].[decrypted_data_table]
    
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
    DECLARE @sqlString              nvarchar(1024)
    DECLARE @KEY                    varbinary(8000)
    DECLARE @IV                     varbinary(8000)
    
    
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
        END
        
        
        DECLARE project_cursor CURSOR LOCAL
            FOR SELECT [project_id] FROM [internal].[projects]
        OPEN project_cursor
        
        FETCH NEXT FROM project_cursor
            INTO @project_id
        
        
        WHILE (@@FETCH_STATUS = 0)
        BEGIN
            
            DELETE @decrypt_project_values
            DELETE @decrypt_parameter_values
            
            
            SET @key_name = 'MS_Enckey_Proj_'+CONVERT(varchar(1024),@project_id)
            SET @certificate_name = 'MS_Cert_Proj_'+CONVERT(varchar(1024),@project_id)
            
            SELECT @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name + ' DECRYPTION BY CERTIFICATE '+ @certificate_name
            EXECUTE sp_executesql @sqlString
            
            SELECT @KEY = DECRYPTBYKEY([key]), @IV = DECRYPTBYKEY([IV]) 
                FROM [internal].[catalog_encryption_keys]
                WHERE [key_name] = @key_name
            IF (@KEY IS NULL OR @IV IS NULL)
            BEGIN
                RAISERROR(27117, 16 ,1) WITH NOWAIT
            END
            
            INSERT @decrypt_project_values 
            SELECT [object_version_lsn], [internal].[decrypt_lob_data](@old_algorithm_name, @KEY, @IV,object_data)            
               FROM [internal].[object_versions] 
               WHERE [object_id] = @project_id 
               AND [object_type] = 20
               
            
            INSERT @decrypt_parameter_values
            SELECT [parameter_id], DECRYPTBYKEY(sensitive_default_value)           
               FROM [internal].[object_parameters] 
               WHERE [project_id] = @project_id 
               AND [value_type] = 'V' 
               AND [value_set] = 1
    
            
            SELECT @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString
        
            
            SELECT @sqlString = 'DROP SYMMETRIC KEY ' + @key_name
            EXECUTE sp_executesql @sqlString
            SELECT @sqlString = 'CREATE SYMMETRIC KEY '+ @key_name + ' WITH ALGORITHM = ' 
                + @algorithm_name + ' ENCRYPTION BY CERTIFICATE ' + @certificate_name
            EXECUTE sp_executesql @sqlString
            
            
            SELECT @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name + ' DECRYPTION BY CERTIFICATE '+ @certificate_name
            EXECUTE sp_executesql @sqlString
            
            
            EXEC internal.[create_key_information] @algorithm_name, @KEY output, @IV output
            
            UPDATE [internal].[catalog_encryption_keys]
                SET [key] = ENCRYPTBYKEY( KEY_GUID(@key_name), @KEY), 
                    [IV] = ENCRYPTBYKEY( KEY_GUID(@key_name), @IV )
                WHERE key_name = @key_name
            
            
            UPDATE [internal].[object_parameters] 
                SET sensitive_default_value =  EncryptByKey(KEY_GUID(@key_name),src.value)
                FROM @decrypt_parameter_values src
                WHERE parameter_id = src.id
                
            
            UPDATE [internal].[object_versions] 
                SET object_data =  [internal].[encrypt_lob_data](@algorithm_name,@KEY, @IV, src.value)
                FROM @decrypt_project_values src
                WHERE [object_version_lsn] = src.id
            
            
            SELECT @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString
            
            
            FETCH NEXT FROM project_cursor
                INTO @project_id            
        END
        CLOSE project_cursor
        DEALLOCATE project_cursor
        
        
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        
        IF (CURSOR_STATUS('local', 'project_cursor') = 1 
            OR CURSOR_STATUS('local', 'project_cursor') = 0)
        BEGIN
            CLOSE project_cursor
            DEALLOCATE project_cursor            
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
