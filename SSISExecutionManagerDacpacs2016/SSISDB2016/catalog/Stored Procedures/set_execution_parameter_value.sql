
CREATE PROCEDURE [catalog].[set_execution_parameter_value]
        @execution_id       bigint,   
        @object_type        smallint, 
        @parameter_name     nvarchar(128), 
        @parameter_value    sql_variant 
WITH EXECUTE AS 'AllSchemaOwner'
AS 
    SET NOCOUNT ON
    
    
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
            RAISERROR(27123, 16, 1) WITH NOWAIT
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
            RAISERROR(27123, 16, 1) WITH NOWAIT
            RETURN 1
    END
    
    DECLARE @result int
    DECLARE @execution_parameter_id bigint
    DECLARE @sensitive bit
    DECLARE @data_type  nvarchar(128)
    DECLARE @value varbinary(MAX)
    DECLARE @parameter_type nvarchar(128)
    DECLARE @return_value           bit = 1
    
    IF (@execution_id IS NULL OR @object_type IS NULL 
        OR @parameter_name IS NULL OR @parameter_value IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 1) WITH NOWAIT 
        RETURN 1 
    END   
    
    IF (@object_type NOT IN(20, 30, 50))
    BEGIN
        RAISERROR(27101, 16 , 1, N'object type') WITH NOWAIT
        RETURN 1;
    END

    IF @execution_id <= 0
    BEGIN
        RAISERROR(27101, 16 , 1, N'execution_id') WITH NOWAIT
        RETURN 1;
    END
    
    SET @parameter_type = CONVERT(nvarchar(128), SQL_VARIANT_PROPERTY(@parameter_value, 'BaseType'));
    
    DECLARE @sqlString              nvarchar(1024)
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
    DECLARE @encryption_algorithm   nvarchar(255)    

    
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
        EXECUTE AS CALLER   
            SET @result = [internal].[check_permission] 
                (
                    4,
                    @execution_id,
                    2
                ) 
        REVERT
        
        IF @result = 0
        BEGIN
            RAISERROR(27103 , 16 , 1, @execution_id) WITH NOWAIT        
        END  
        
        DECLARE @project_id bigint
        DECLARE @status int
        EXECUTE AS CALLER
            SELECT @project_id = [object_id], @status = [status]
            FROM [catalog].[operations]
            WHERE [operation_id] = @execution_id 
                  AND [object_type] = 20
                  AND [operation_type] = 200
        REVERT
        
        IF (@project_id IS NULL)
        BEGIN
            RAISERROR(27103 , 16 , 1, @execution_id) WITH NOWAIT
        END
       
        IF  @status <> 1
        BEGIN
            RAISERROR(27224 , 16 , 1) WITH NOWAIT
        END
       
       
        SELECT @execution_parameter_id = [execution_parameter_id],
               @sensitive = [sensitive],
               @data_type = [parameter_data_type]
        FROM   [internal].[execution_parameter_values]
        WHERE  [execution_id] = @execution_id AND [object_type] = @object_type 
               AND [parameter_name] = @parameter_name COLLATE SQL_Latin1_General_CP1_CS_AS
       
        IF @execution_parameter_id IS NULL 
        BEGIN
            RAISERROR(27176 , 16 , 1, @parameter_name) WITH NOWAIT        
        END  
        
        ELSE IF @sensitive IS NULL OR @data_type IS NULL
        BEGIN
            RAISERROR(27205, 16 , 1) WITH NOWAIT        
        END          
        
        IF NOT EXISTS (SELECT [ssis_data_type] FROM [internal].[data_type_mapping]
              WHERE [ssis_data_type] = @data_type)
        BEGIN
            RAISERROR(27159, 16 , 1) WITH NOWAIT        
        END        
        
        EXEC @return_value = [internal].[check_data_type_value] 
            @parameter_value, @data_type
     
        IF (@return_value <> 0)         
        
        BEGIN
            RAISERROR(27147, 16 , 1, @data_type) WITH NOWAIT
        END 

        EXEC @return_value = [internal].[check_parameter_value_by_name] 
            @parameter_value, @parameter_name
     
        IF (@return_value <> 0)         
        
        BEGIN
            RETURN 1
        END 
       
        DECLARE @server_operation_encryption_level int
        SELECT @server_operation_encryption_level = CONVERT(int,property_value)  
                FROM [catalog].[catalog_properties]
                WHERE property_name = 'SERVER_OPERATION_ENCRYPTION_LEVEL'

        IF @server_operation_encryption_level NOT in (1, 2)       
        BEGIN
            RAISERROR(27163    ,16,1,'SERVER_OPERATION_ENCRYPTION_LEVEL') WITH NOWAIT
        END
       
        IF @sensitive = 1
        BEGIN
            IF @server_operation_encryption_level = 1
            BEGIN
            SET @key_name = 'MS_Enckey_Exec_'+CONVERT(varchar,@execution_id)
            SET @certificate_name = 'MS_Cert_Exec_'+CONVERT(varchar,@execution_id) 
            END
            ELSE BEGIN
                SET @key_name = 'MS_Enckey_Proj_Param_'+CONVERT(varchar,@project_id)
                SET @certificate_name = 'MS_Cert_Proj_Param_'+CONVERT(varchar,@project_id) 
            END
     
            SET @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name 
                + ' DECRYPTION BY CERTIFICATE ' + @certificate_name  
            EXECUTE sp_executesql @sqlString
            
            IF @data_type = 'datetime'
            BEGIN
                SET @value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(4000),CONVERT(datetime2,@parameter_value)))
            END
            
            ELSE IF @data_type = 'single' OR @data_type = 'double' OR @data_type = 'decimal'
            BEGIN
                SET @value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(4000),CONVERT(decimal(38,18),@parameter_value)))
            END
                                 
            ELSE
            BEGIN
                SET @value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(MAX),@parameter_value))   
            END
            
            SET @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString  
            
            UPDATE [internal].[execution_parameter_values]
            SET [runtime_override] = 1,
                [value_set] = 1,
                [base_data_type] = @parameter_type,
                [sensitive_parameter_value] = @value
            WHERE [execution_parameter_id] = @execution_parameter_id           
            
        END
        
        ELSE
        BEGIN
            UPDATE [internal].[execution_parameter_values]
            SET [runtime_override] = 1,
                [value_set] = 1,
                [base_data_type] = @parameter_type,
                [parameter_value] = @parameter_value
            WHERE [execution_parameter_id] = @execution_parameter_id

            
            

            IF @parameter_name = 'LOGGING_LEVEL'
            BEGIN
                DECLARE @converted_value int
                SET @converted_value = CONVERT(int,@parameter_value)

                IF (@converted_value = 100)
                BEGIN
                    INSERT INTO [internal].[execution_parameter_values]
                    (
                        [execution_id],
                        [object_type],
                        [parameter_data_type],
                        [parameter_name],
                        [parameter_value],
                        [base_data_type],
                        [sensitive], 
                        [required],
                        [value_set],
                        [runtime_override]
                    )
                    VALUES 
                    (
                        @execution_id,
                        50,
                        'String',
                        'CUSTOMIZED_LOGGING_LEVEL',
                        CONVERT(sql_variant,''),
                        'sysname',
                        0,
                        0,
                        1,
                        0
                    )
                END
            END
        END

        
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        THROW;
    END CATCH
     
    RETURN 0
