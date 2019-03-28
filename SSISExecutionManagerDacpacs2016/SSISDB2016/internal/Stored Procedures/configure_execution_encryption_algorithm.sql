
CREATE PROCEDURE [internal].[configure_execution_encryption_algorithm]
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
    
    DECLARE @execution_id bigint
    DECLARE @decrypt_values [internal].[decrypted_data_table]
    DECLARE @decrypt_property_override_values [internal].[decrypted_data_table]
    
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
    DECLARE @sqlString              nvarchar(1024)
    DECLARE @server_operation_encryption_level       int


    SELECT @server_operation_encryption_level = CONVERT(int,property_value)  
            FROM [catalog].[catalog_properties]
            WHERE property_name = 'SERVER_OPERATION_ENCRYPTION_LEVEL'

    IF @server_operation_encryption_level NOT in (1, 2)     
    BEGIN
        RAISERROR(27163    ,16,1,'SERVER_OPERATION_ENCRYPTION_LEVEL') WITH NOWAIT
        RETURN 1
    END
    
    
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
    IF @server_operation_encryption_level = 1
    BEGIN
    BEGIN TRY
        
        IF EXISTS (SELECT operation_id FROM [internal].[operations]
                WHERE [status] IN (2, 5)
                AND   [operation_id] <> @operation_id )
        BEGIN    
            RAISERROR(27139, 16, 1) WITH NOWAIT
            RETURN 1
        END
        
        
        DECLARE execution_cursor CURSOR LOCAL
            FOR SELECT [execution_id] FROM [internal].[executions]
        OPEN execution_cursor
        
        FETCH NEXT FROM execution_cursor
            INTO @execution_id
        
        
        WHILE (@@FETCH_STATUS = 0)
        BEGIN
            
            DELETE @decrypt_values
            DELETE @decrypt_property_override_values
            
            
            SET @key_name = 'MS_Enckey_Exec_'+CONVERT(varchar(1024),@execution_id)
            SET @certificate_name = 'MS_Cert_Exec_'+CONVERT(varchar(1024),@execution_id)
            
            SELECT @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name + ' DECRYPTION BY CERTIFICATE '+ @certificate_name
            EXECUTE sp_executesql @sqlString
    
            
            INSERT @decrypt_values 
            SELECT [execution_parameter_id], DECRYPTBYKEY(sensitive_parameter_value)            
               FROM [internal].[execution_parameter_values] 
               WHERE [execution_id] = @execution_id
               AND [sensitive] = 1
               AND [value_set] = 1
    
            INSERT @decrypt_property_override_values 
            SELECT [property_id], DECRYPTBYKEY(sensitive_property_value)            
               FROM [internal].[execution_property_override_values] 
               WHERE [execution_id] = @execution_id
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
            
            
            UPDATE [internal].[execution_parameter_values] 
                SET sensitive_parameter_value =  EncryptByKey(KEY_GUID(@key_name),src.value)
                FROM @decrypt_values src
                WHERE execution_parameter_id = src.id
            
            
            UPDATE [internal].[execution_property_override_values] 
                SET sensitive_property_value =  EncryptByKey(KEY_GUID(@key_name),src.value)
                FROM @decrypt_property_override_values src
                WHERE property_id = src.id

            
            SELECT @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString
            
            
            FETCH NEXT FROM execution_cursor
                INTO @execution_id            
        END
        CLOSE execution_cursor
        DEALLOCATE execution_cursor
        
        
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           

        
        IF (CURSOR_STATUS('local', 'execution_cursor') = 1 
            OR CURSOR_STATUS('local', 'execution_cursor') = 0)
        BEGIN
            CLOSE execution_cursor
            DEALLOCATE execution_cursor            
        END
            IF (@key_name <> '')
            BEGIN
                SET @sqlString = 'IF EXISTS (SELECT key_name FROM sys.openkeys WHERE key_name = ''' + @key_name +''') ' 
                  + 'CLOSE SYMMETRIC KEY '+ @key_name
                EXECUTE sp_executesql @sqlString
            END;
            THROW;
        END CATCH
    END
    ELSE 
    BEGIN
        BEGIN TRY
             
            IF EXISTS (SELECT operation_id FROM [internal].[operations]
                WHERE [status] IN (2, 5)
                AND   [operation_id] <> @operation_id )
            BEGIN
                RAISERROR(27139, 16, 1) WITH NOWAIT
                RETURN 1
            END

            
            DECLARE project_cursor CURSOR LOCAL
                FOR SELECT [project_id] FROM [internal].[projects]

            CREATE TABLE #decryped_values_table (execution_parameter_id bigint, execution_id bigint, 
                decrypt_values varbinary(MAX))
                        
            CREATE TABLE #decryped_property_override_values_table(property_id bigint, execution_id bigint, 
                decrypt_property_override_values varbinary(MAX))

            DECLARE @project_id bigint

            OPEN project_cursor
            FETCH NEXT FROM project_cursor
                INTO @project_id

            
            WHILE (@@FETCH_STATUS = 0)
            BEGIN
                
                SET @key_name = 'MS_Enckey_Proj_Param_' + CONVERT(varchar(1024),@project_id)
                SET @certificate_name = 'MS_Cert_Proj_Param_' + CONVERT(varchar(1024),@project_id)

                IF EXISTS (SELECT * from sys.symmetric_keys WHERE name = @key_name)
                BEGIN
                    SELECT @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name + ' DECRYPTION BY CERTIFICATE '+ @certificate_name
                    EXECUTE sp_executesql @sqlString

                    TRUNCATE TABLE #decryped_values_table
                    TRUNCATE TABLE #decryped_property_override_values_table

                    INSERT INTO #decryped_values_table(execution_parameter_id, execution_id, decrypt_values) 
                        SELECT [execution_parameter_id],[execution_id], DECRYPTBYKEY(sensitive_parameter_value)
                        FROM [internal].[execution_parameter_values] inner join [internal].[operations] ON 
                                [execution_parameter_values].[execution_id] = [operations].[operation_id]
                        WHERE [operations].[object_id] = @project_id
                            AND [execution_parameter_values].[sensitive] = 1
                            AND [execution_parameter_values].[value_set] = 1

                    INSERT INTO #decryped_property_override_values_table(property_id, execution_id,decrypt_property_override_values)
                        SELECT [property_id], [execution_id],DECRYPTBYKEY(sensitive_property_value)
                        FROM [internal].[execution_property_override_values] inner join [internal].[operations] ON
                            [execution_property_override_values].[execution_id] = [operations].[operation_id]
                        WHERE [operations].[object_id] = @project_id
                        AND [execution_property_override_values].[sensitive] = 1

                    
                    SELECT @sqlString = 'DROP SYMMETRIC KEY ' + @key_name
                    EXECUTE sp_executesql @sqlString
                    SELECT @sqlString = 'CREATE SYMMETRIC KEY '+ @key_name + ' WITH ALGORITHM = ' 
                        + @algorithm_name + ' ENCRYPTION BY CERTIFICATE ' + @certificate_name
                    EXECUTE sp_executesql @sqlString
               
                    
                    SELECT @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name + ' DECRYPTION BY CERTIFICATE '+ @certificate_name
                    EXECUTE sp_executesql @sqlString

                    
                    UPDATE [internal].[execution_parameter_values] 
                        SET sensitive_parameter_value =  EncryptByKey(KEY_GUID(@key_name),#decryped_values_table.decrypt_values)
                        FROM #decryped_values_table
                        WHERE [execution_parameter_values].[execution_id] = #decryped_values_table.execution_id
                            AND [execution_parameter_values].[execution_parameter_id] = #decryped_values_table.execution_parameter_id

                    
                    UPDATE [internal].[execution_property_override_values] 
                        SET sensitive_property_value =  EncryptByKey(KEY_GUID(@key_name),#decryped_property_override_values_table.decrypt_property_override_values)
                        FROM #decryped_property_override_values_table
                        WHERE [execution_property_override_values].[property_id] = #decryped_property_override_values_table.property_id
                            AND [execution_property_override_values].[execution_id] = #decryped_property_override_values_table.execution_id

                    
                    SELECT @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
                    EXECUTE sp_executesql @sqlString
                END
                FETCH NEXT FROM project_cursor
                    INTO @project_id
            END
        
            CLOSE project_cursor

            DEALLOCATE project_cursor
            DROP TABLE #decryped_values_table
            DROP TABLE #decryped_property_override_values_table

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
    END
    RETURN 0
