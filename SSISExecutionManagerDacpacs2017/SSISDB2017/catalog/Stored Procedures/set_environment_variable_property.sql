
CREATE PROCEDURE [catalog].[set_environment_variable_property]
        @folder_name        nvarchar(128),        
        @environment_name   nvarchar(128),        
        @variable_name      nvarchar(128),        
        @property_name      nvarchar(128),        
        @property_value     nvarchar(4000)        
AS
    SET NOCOUNT ON 
    
    DECLARE @result bit
    
    
    DECLARE @caller_id     int
    DECLARE @caller_name   [internal].[adt_sname]
    DECLARE @caller_sid    [internal].[adt_sid]
    DECLARE @suser_name    [internal].[adt_sname]
    DECLARE @suser_sid     [internal].[adt_sid]
    
    EXECUTE AS CALLER
        EXEC [internal].[get_user_info]
            @caller_name OUTPUT,
            @caller_sid OUTPUT,
            @suser_name OUTPUT,
            @suser_sid OUTPUT,
            @caller_id OUTPUT;
          
          
        IF(
            EXISTS(SELECT [name]
                    FROM sys.server_principals
                    WHERE [sid] = @suser_sid AND [type] = 'S')  
            OR
            EXISTS(SELECT [name]
                    FROM sys.database_principals
                    WHERE ([sid] = @caller_sid AND [type] = 'S')) 
            )
        BEGIN
            RAISERROR(27123, 16, 7) WITH NOWAIT
            RETURN 1
        END
    REVERT
    
    IF(
            EXISTS(SELECT [name]
                    FROM sys.server_principals
                    WHERE [sid] = @suser_sid AND [type] = 'S')  
            OR
            EXISTS(SELECT [name]
                    FROM sys.database_principals
                    WHERE ([sid] = @caller_sid AND [type] = 'S')) 
            )
    BEGIN
            RAISERROR(27123, 16, 7) WITH NOWAIT
            RETURN 1
    END    
    
    IF (@folder_name IS NULL OR @environment_name IS NULL OR
            @variable_name IS NULL OR @property_name IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
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
    
    BEGIN TRY   
        
    DECLARE @environment_id bigint;
    EXECUTE AS CALLER
        SET @environment_id = (SELECT env.[environment_id]
                                FROM [catalog].[environments] env INNER JOIN [catalog].[folders] fld
                                ON env.[folder_id] = fld.[folder_id]
                                AND env.[name] = @environment_name
                                AND fld.name = @folder_name);
    REVERT
    IF @environment_id IS NULL
    BEGIN
        RAISERROR(27182 , 16 , 1, @environment_name) WITH NOWAIT
    END
    EXECUTE AS CALLER
        SET @result = [internal].[check_permission]
        (
            3,
            @environment_id,
            2
         )
   REVERT
   IF @result = 0
   BEGIN
       RAISERROR(27182 , 16 , 1, @environment_name) WITH NOWAIT
   END 
        
        
    DECLARE @variable_id    bigint
    SET @variable_id = (SELECT [variable_id] FROM [internal].[environment_variables]
                            WHERE [environment_id] = @environment_id AND [name] = @variable_name)
    IF (@variable_id IS NULL)
    BEGIN
        RAISERROR(27183 , 16 , 1, @variable_name) WITH NOWAIT
    END  

        IF (@property_name = 'DESCRIPTION')
        BEGIN
            UPDATE [internal].[environment_variables] 
                SET [description] = @property_value 
                WHERE [environment_id] = @environment_id AND [name] = @variable_name
            IF @@ROWCOUNT <> 1
            BEGIN
                RAISERROR(27112, 16, 1, N'environment_variables') WITH NOWAIT
            END
        END
        ELSE IF (@property_name = 'NAME')
        BEGIN
            
            IF [internal].[is_valid_name](@property_value) = 0
            BEGIN
                RAISERROR(27180, 16, 1, @property_value) WITH NOWAIT
            END
            
            
            IF EXISTS (SELECT [name] FROM [internal].[environment_variables]
                WHERE [name] = @property_value AND [environment_id] = @environment_id
                AND [name] <> @variable_name)
            BEGIN
                RAISERROR(27173 , 16 , 1, @property_value) WITH NOWAIT
            END
            UPDATE [internal].[environment_variables] 
                SET [name] = @property_value 
                WHERE [environment_id] = @environment_id AND [name] = @variable_name
            IF @@ROWCOUNT <> 1
            BEGIN
                RAISERROR(27112, 16, 1, N'environment_variables') WITH NOWAIT
            END
        END
        
        ELSE IF (@property_name = 'TYPE')
        BEGIN
            DECLARE @sensitive bit
            DECLARE @origin_data_type nvarchar(128) 
            DECLARE @value sql_variant
            DECLARE @new_value sql_variant
            DECLARE @sensitive_value varbinary(MAX)
            DECLARE @sqlString      nvarchar(1024) 
            DECLARE @key_name               [internal].[adt_name] 
            DECLARE @certificate_name       [internal].[adt_name]
            DECLARE @base_type nvarchar(128) 

            
            IF NOT EXISTS (SELECT [ssis_data_type] FROM [internal].[data_type_mapping]
                   WHERE [ssis_data_type] = @property_value)
            BEGIN
                RAISERROR(27159, 16 , 1) WITH NOWAIT
            END
            
            
            SELECT @sensitive = [sensitive], @origin_data_type = [type], 
                @value = [value], @sensitive_value = [sensitive_value]
                FROM [internal].[environment_variables]
                WHERE [variable_id] = @variable_id
            
            
            IF (@origin_data_type <> @property_value)
            BEGIN
                IF (@sensitive = 1)
                BEGIN
                    
                    SET @key_name = 'MS_Enckey_Env_'+CONVERT(varchar,@environment_id)
                    SET @certificate_name = 'MS_Cert_Env_'+CONVERT(varchar,@environment_id)
                    
                    DECLARE @decrypted_value    varbinary(MAX)
                                
                    SET @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name 
                                + ' DECRYPTION BY CERTIFICATE ' + @certificate_name  
                    EXECUTE sp_executesql @sqlString
            
                    SET @decrypted_value = DECRYPTBYKEY(@sensitive_value)
            
                    SET @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name   

                    SET @value = [internal].[get_value_by_data_type] (@decrypted_value, @origin_data_type)  

                    
                    
                    SET @new_value = [internal].convert_value(@value, @property_value)
                    if(@new_value IS NULL)
                    BEGIN
                        RAISERROR(27210, 16, 1, @origin_data_type, @property_value) WITH NOWAIT
                    END

                    
                    SET @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name 
                                + ' DECRYPTION BY CERTIFICATE ' + @certificate_name  
                    EXECUTE sp_executesql @sqlString
                    IF @property_value = 'datetime'
                    BEGIN
                        SET @sensitive_value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(4000),CONVERT(datetime2,@new_value)))
                    END
            
                    ELSE IF @property_value = 'single' OR @property_value = 'double' OR @property_value = 'decimal'
                    BEGIN
                        SET @sensitive_value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(4000),CONVERT(decimal(38,18),@new_value)))
                    END
                        
                    ELSE
                    BEGIN
                        SET @sensitive_value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(MAX),@new_value))   
                    END
            
                    SET @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
                    EXECUTE sp_executesql @sqlString

                    SET @base_type = CONVERT(sysname, SQL_VARIANT_PROPERTY(@new_value, 'BaseType'));

                    UPDATE [internal].[environment_variables] 
                        SET [type] = @property_value, [sensitive_value] = @sensitive_value, 
                            [base_data_type] = @base_type
                        WHERE [environment_id] = @environment_id AND [name] = @variable_name
                    IF @@ROWCOUNT <> 1
                    BEGIN
                        RAISERROR(27112, 16, 1, N'environment_variables') WITH NOWAIT
                    END

                END

                ELSE
                BEGIN
                    
                    SET @new_value = [internal].convert_value(@value, @property_value)
                    if(@new_value IS NULL)
                    BEGIN
                        RAISERROR(27210, 16, 1, @origin_data_type, @property_value) WITH NOWAIT
                    END
                    SET @base_type = CONVERT(sysname, SQL_VARIANT_PROPERTY(@new_value, 'BaseType'));

                    UPDATE [internal].[environment_variables] 
                        SET [type] = @property_value, [value] = @new_value, [base_data_type] = @base_type
                        WHERE [environment_id] = @environment_id AND [name] = @variable_name
                    IF @@ROWCOUNT <> 1
                    BEGIN
                        RAISERROR(27112, 16, 1, N'environment_variables') WITH NOWAIT
                    END
                END     
            END    
        END
        ELSE
        BEGIN
            RAISERROR(27101, 16 , 1, 'DESCRIPTION') WITH NOWAIT      
        END
    
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
    
    RETURN 0  
