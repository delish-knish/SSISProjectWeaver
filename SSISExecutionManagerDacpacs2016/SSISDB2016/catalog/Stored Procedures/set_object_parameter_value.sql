
CREATE PROCEDURE [catalog].[set_object_parameter_value]
        @object_type            smallint,
        @folder_name            nvarchar(128),
        @project_name           nvarchar(128),
        @parameter_name         nvarchar(128),
        @parameter_value        sql_variant,
        @object_name            nvarchar(260) = null,
        @value_type             char(1) = 'V'
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON
     
    DECLARE @result bit
    DECLARE @sensitive bit
    DECLARE @parameter_id bigint
    DECLARE @parameter_data_type nvarchar(128)
    DECLARE @parameter_type nvarchar(128)
    DECLARE @return_value           bit = 1
    
    
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
       
    IF (@folder_name IS NULL OR @project_name IS NULL 
            OR @parameter_name IS NULL OR @parameter_value IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1     
    END    
    
    IF @object_type NOT IN (20, 30)
    BEGIN
        RAISERROR(27101, 16 , 1, N'object_type') WITH NOWAIT
        RETURN 1;
    END
    
    IF @value_type NOT IN ('V', 'R')
    BEGIN
        RAISERROR(27101, 16 , 1, N'value_type') WITH NOWAIT
        RETURN 1;
    END
    
    SET @parameter_type = CONVERT(nvarchar(128), SQL_VARIANT_PROPERTY(@parameter_value, 'BaseType'));
    IF @parameter_type IS NULL
    BEGIN
        RAISERROR(27159, 16 , 1) WITH NOWAIT 
        RETURN 1   
    END  
       
    DECLARE @encrypted_value        varbinary(MAX)
    DECLARE @sqlString              nvarchar(1024)
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
    
    
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
    
        
    DECLARE @project_id bigint;
    EXECUTE AS CALLER
        SET @project_id = (SELECT projs.[project_id]
                                FROM [catalog].[projects] projs INNER JOIN [catalog].[folders] fld
                                ON projs.[folder_id] = fld.[folder_id]
                                AND projs.[name] = @project_name
                                AND fld.name = @folder_name);
    REVERT
    IF @project_id IS NULL
    BEGIN
        RAISERROR(27109 , 16 , 1, @project_name) WITH NOWAIT
    END
    EXECUTE AS CALLER
        SET @result = [internal].[check_permission]
        (
            2,
            @project_id,
            2
         )
    REVERT
    IF @result = 0
    BEGIN
        RAISERROR(27109 , 16 , 1, @project_name) WITH NOWAIT
    END
        
        SET @key_name = 'MS_Enckey_Proj_'+CONVERT(varchar,@project_id)
        SET @certificate_name = 'MS_Cert_Proj_'+CONVERT(varchar,@project_id)
        
        IF @object_type = 20  
        BEGIN
            SELECT @parameter_id = [parameter_id], @sensitive = [sensitive],
                @parameter_data_type = [data_type]
                FROM [catalog].[object_parameters]
                WHERE [project_id] = @project_id AND [object_type] = @object_type
                AND [parameter_name] = @parameter_name COLLATE SQL_Latin1_General_CP1_CS_AS
        END
        ELSE IF @object_type = 30  
        BEGIN
            SELECT @parameter_id = [parameter_id], @sensitive = [sensitive],
                @parameter_data_type = [data_type]
                FROM [catalog].[object_parameters]
                WHERE [project_id] = @project_id AND [object_type] = @object_type
                AND [parameter_name] = @parameter_name COLLATE SQL_Latin1_General_CP1_CS_AS
                AND [object_name] = @object_name
        END
        
        IF @parameter_id IS NULL
        BEGIN
            RAISERROR(27106 , 16 , 1, @parameter_name) WITH NOWAIT     
        END
        
        IF @value_type = 'V'
        BEGIN
            EXEC @return_value = [internal].[check_data_type_value] 
                @parameter_value, @parameter_data_type
         
            IF (@return_value <> 0)         
            
            BEGIN
                RAISERROR(27147, 16 , 1, @parameter_data_type) WITH NOWAIT
            END 
            
            IF @sensitive = 0 
            BEGIN
                UPDATE [internal].[object_parameters]
                    SET [default_value] = @parameter_value,
                        [sensitive_default_value] = NULL,
                        [base_data_type] = @parameter_type,
                        [value_type] = @value_type,
                        [value_set] = 1,
                        [referenced_variable_name] = NULL
                WHERE parameter_id = @parameter_id
                IF @@ROWCOUNT <> 1
                BEGIN
                    RAISERROR(27112, 16, 1, N'object_parameters') WITH NOWAIT
                END
            END
            
            ELSE
            BEGIN
                SET @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name 
                                    + ' DECRYPTION BY CERTIFICATE ' + @certificate_name  
                EXECUTE sp_executesql @sqlString
                
                IF @parameter_data_type = 'datetime'
                BEGIN
                    SET @encrypted_value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(4000),CONVERT(datetime2,@parameter_value)))
                END
                
                ELSE IF @parameter_data_type = 'single' OR @parameter_data_type = 'double' OR @parameter_data_type = 'decimal'
                BEGIN
                    SET @encrypted_value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(4000),CONVERT(decimal(38,18),@parameter_value)))
                END
                            
                ELSE
                BEGIN
                    SET @encrypted_value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(MAX),@parameter_value))   
                END
                
                SET @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
                
                EXECUTE sp_executesql @sqlString
                                
                UPDATE [internal].[object_parameters]
                    SET [default_value] = NULL,
                        [sensitive_default_value] = @encrypted_value,
                        [base_data_type] = @parameter_type,
                        [value_type] = @value_type,
                        [value_set] = 1,
                        [referenced_variable_name] = NULL
                WHERE parameter_id = @parameter_id
                IF @@ROWCOUNT <> 1
                BEGIN
                    RAISERROR(27112, 16, 1, N'object_parameters') WITH NOWAIT
                END                
            END
        END
        
        ELSE IF @value_type = 'R'  
        BEGIN
            UPDATE [internal].[object_parameters]
                SET [default_value] = NULL,
                    [sensitive_default_value] = NULL,
                    [base_data_type] = NULL,
                    [value_type] = @value_type,
                    [value_set] = 1,
                    [referenced_variable_name] = CONVERT(nvarchar(128), @parameter_value)
            WHERE parameter_id = @parameter_id
            IF @@ROWCOUNT <> 1
            BEGIN
                RAISERROR(27112, 16, 1, N'object_parameters') WITH NOWAIT
            END
                   
            
            
            IF EXISTS(
            SELECT envs.[environment_name]
            FROM ([catalog].[object_parameters] params 
            INNER JOIN [internal].[environment_references] envs
                ON params.[project_id] = envs.[project_id]) 
            INNER JOIN([internal].[environments] e 
            INNER JOIN [internal].[folders] f
                ON e.[folder_id] = f.[folder_id] 
            INNER JOIN [internal].[environment_variables] vars
                ON e.[environment_id] = vars.[environment_id])
                ON envs.[environment_folder_name] = f.[name] 
                AND envs.[environment_name] = e.[environment_name]
                AND params.[referenced_variable_name] = vars.[name] 
                AND [params].[data_type] <> vars.[type]
            WHERE params.[parameter_id] = @parameter_id 
                AND envs.[reference_type] = 'A'
            
            UNION 
            
            SELECT envs.[environment_name]
            FROM ([catalog].[object_parameters] params 
            INNER JOIN [internal].[environment_references] envs
                ON params.[project_id] = envs.[project_id] 
            INNER JOIN [catalog].[projects] projs 
                ON projs.[project_id] = params.[project_id]) 
            INNER JOIN ([internal].[environments] e  
                INNER JOIN [internal].[environment_variables] vars
                    ON e.[environment_id] = vars.[environment_id])
                ON e.[folder_id] = projs.[folder_id] 
                AND envs.[environment_name] = e.[environment_name]
                AND params.[referenced_variable_name] = vars.[name] 
                AND [params].[data_type] <> vars.[type]
            WHERE params.[parameter_id] = @parameter_id AND envs.[reference_type] = 'R'                     
            )
            BEGIN
                
                RAISERROR(27148 , 10 , 1) WITH NOWAIT 
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
              
        THROW 
    END CATCH
    
    RETURN 0      
    
