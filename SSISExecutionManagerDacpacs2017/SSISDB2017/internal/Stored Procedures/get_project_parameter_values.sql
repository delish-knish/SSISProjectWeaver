CREATE PROCEDURE [internal].[get_project_parameter_values]
        @execution_id bigint,		    
        @project_id bigint,				
        @version_id bigint             
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON
    DECLARE @result bit
    DECLARE @environment_id bigint
    DECLARE @environment_found bit

    DECLARE @sqlString              nvarchar(1024)
    DECLARE @encryption_algorithm   nvarchar(255)

    DECLARE @env_key_name               [internal].[adt_name]
    DECLARE @env_certificate_name       [internal].[adt_name]
    
    DECLARE @project_key_name               [internal].[adt_name]
    DECLARE @project_certificate_name       [internal].[adt_name]
    
    IF (@execution_id IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 1) WITH NOWAIT 
        RETURN 1;
    END   

    IF @execution_id <= 0
    BEGIN
        RAISERROR(27101, 16 , 1, N'execution_id') WITH NOWAIT
        RETURN 1;
    END
    
    DECLARE @id bigint
	DECLARE @reference_id bigint

    EXECUTE AS CALLER
        SELECT @id = [execution_id], @reference_id = [reference_id] FROM [catalog].[executions]
            WHERE [execution_id] = @execution_id 
    REVERT    
        
    IF @id IS NULL
    BEGIN
        RAISERROR(27103 , 16 , 1, @execution_id) WITH NOWAIT
		RETURN 1;
    END
	
	SET @encryption_algorithm = (SELECT [internal].[get_encryption_algorithm]())
    
    IF @encryption_algorithm IS NULL
    BEGIN
        RAISERROR(27156, 16, 1, 'ENCRYPTION_ALGORITHM') WITH NOWAIT
		RETURN 1;
    END    
        
    IF @project_id IS NULL
    BEGIN
        RAISERROR(27138, 16 , 1) WITH NOWAIT 
        RETURN 1;
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
        
        EXECUTE AS CALLER   
            SET @result =  [internal].[check_permission] 
                (
                    2,
                    @project_id,
                    3
                 ) 
        REVERT
        
        IF @result = 0
        BEGIN
            RAISERROR(27146, 16, 1) WITH NOWAIT
        END
        
        DECLARE @environment_name nvarchar(128)
        DECLARE @environment_folder_name nvarchar(128)
        DECLARE @reference_type char(1)
        
        
        IF(@reference_id IS NOT NULL)
        BEGIN
            
            EXECUTE AS CALLER
                SELECT @environment_name = environment_name,
                       @environment_folder_name = environment_folder_name,
                       @reference_type = reference_type
                FROM [catalog].[environment_references]
                WHERE project_id = @project_id AND reference_id = @reference_id
            REVERT
            IF (@environment_name IS NULL)
            BEGIN
                RAISERROR(27208, 16, 1, @reference_id) WITH NOWAIT
            END                                                     
            
            
            SET @environment_found = 1
            IF (@reference_type = 'A')
            BEGIN
                SELECT @environment_id = envs.[environment_id]
                FROM [internal].[folders] fds INNER JOIN [internal].[environments] envs
                ON fds.[folder_id] = envs.[folder_id]
                WHERE envs.[environment_name] = @environment_name AND fds.[name] = @environment_folder_name
            END
            ELSE IF (@reference_type = 'R')
            BEGIN
                SELECT @environment_id = envs.[environment_id]
                FROM  [internal].[projects] projs INNER JOIN [internal].[environments] envs
                ON projs.[folder_id] = envs.[folder_id]
                WHERE envs.[environment_name] = @environment_name AND projs.[project_id] = @project_id
            END
            IF (@environment_id IS NULL)
            BEGIN
                SET @environment_found = 0
            END
            
            EXECUTE AS CALLER
                SET @result =  [internal].[check_permission]
                    (
                        3,
                        @environment_id,
                        1
                     )
            REVERT
            IF @result = 0
            BEGIN
                SET @environment_found = 0
            END
                    
            IF @environment_found = 0
            BEGIN
                RAISERROR(27182 , 16 , 1, @environment_name) WITH NOWAIT
            END                      
        END
        
        IF @environment_id IS NOT NULL
        BEGIN
            SET @env_key_name = 'MS_Enckey_Env_'+CONVERT(varchar,@environment_id)
            SET @env_certificate_name = 'MS_Cert_Env_'+CONVERT(varchar,@environment_id)
            
            SET @sqlString = 'OPEN SYMMETRIC KEY ' + @env_key_name 
                    + ' DECRYPTION BY CERTIFICATE ' + @env_certificate_name  
                EXECUTE sp_executesql @sqlString               
        END     
        
            
        SET @project_key_name = 'MS_Enckey_Proj_'+CONVERT(varchar,@project_id)
        SET @project_certificate_name = 'MS_Cert_Proj_'+CONVERT(varchar,@project_id)

        SET @sqlString = 'OPEN SYMMETRIC KEY ' + @project_key_name 
                + ' DECRYPTION BY CERTIFICATE ' + @project_certificate_name  
            EXECUTE sp_executesql @sqlString 

        
        DECLARE @result_set TABLE
        (
            [parameter_data_type] nvarchar(128),
            [parameter_name] nvarchar(128),
            [parameter_value] sql_variant,
            [package_name] nvarchar(260),
            [sensitive]  bit,
            [required]  bit,
            [missing_reference] bit
        );            
            
        
        INSERT INTO @result_set
        SELECT  [parameter_data_type], 
                [parameter_name],
                [default_value], 
                [object_name],
                [sensitive], 
                [required],
                0
        FROM [internal].[object_parameters] 
        WHERE [project_id] = @project_id 
        AND [object_type] = 30
        AND [sensitive] = 0 
        AND [value_type] = 'V' 
        AND [project_version_lsn] = @version_id
        AND [value_set] = 1
        
        INSERT INTO @result_set
        SELECT  [parameter_data_type], 
                [parameter_name],
                [internal].[get_value_by_data_type](DECRYPTBYKEY(sensitive_default_value),[parameter_data_type]), 
                [object_name],
                [sensitive], 
                [required],
                0
        FROM [internal].[object_parameters] 
        WHERE [project_id] = @project_id 
        AND [object_type] = 30
        AND sensitive = 1
        AND [value_set] = 1
        AND [value_type] = 'V' 
        AND [project_version_lsn] = @version_id   
        
        
        IF @environment_id IS NOT NULL
        BEGIN
            INSERT INTO @result_set
            SELECT  params.[parameter_data_type], 
                    params.[parameter_name],
                    vars.[value], 
                    params.[object_name],
                    params.[sensitive], 
                    params.[required],
                    0
            FROM [internal].[object_parameters] params 
            INNER JOIN [internal].[environment_variables] vars
                ON params.[referenced_variable_name] = vars.[name] 
            WHERE params.[project_id] = @project_id 
            AND params.[object_type] = 30
            AND vars.[sensitive] = 0 
            AND params.[value_type] = 'R' 
            AND params.[project_version_lsn] = @version_id
            AND vars.[environment_id] = @environment_id
            AND params.[value_set] = 1
            
            INSERT INTO @result_set
            SELECT  params.[parameter_data_type], 
                    params.[parameter_name],
                    [internal].[get_value_by_data_type](DECRYPTBYKEY(vars.[sensitive_value]), vars.[type]), 
                    params.[object_name],
                    params.[sensitive], 
                    params.[required],
                    0
            FROM [internal].[object_parameters] params 
            INNER JOIN [internal].[environment_variables] vars
                ON params.[referenced_variable_name] = vars.[name] 
            WHERE params.[project_id] = @project_id 
            AND params.[object_type] = 30
            AND vars.[sensitive] = 1 
            AND params.[value_type] = 'R' 
            AND params.[project_version_lsn] = @version_id
            AND vars.[environment_id] = @environment_id
            AND params.[value_set] = 1            
                           
            
            
            INSERT INTO @result_set
            SELECT  params.[parameter_data_type],
                    params.[parameter_name],
                    NULL, 
                    params.[object_name],
                    params.[sensitive], 
                    params.[required],
                    1
            FROM [internal].[object_parameters] params
            WHERE params.[value_type] = 'R'   
            AND params.[project_id] = @project_id
            AND params.[object_type] = 30
            AND params.[referenced_variable_name] NOT IN 
            (SELECT vars.[name] 
                FROM [internal].[environments] envs INNER JOIN [internal].[environment_variables] vars
                    ON envs.[environment_id] = vars.[environment_id]
                WHERE envs.[environment_id] = @environment_id )
                       
        END        
        
        SELECT [parameter_data_type],
            [parameter_name],
            [parameter_value],
            [package_name],
            [sensitive],
            [required],
            [missing_reference]
        FROM @result_set             
        
        IF (@env_key_name <> '')
        BEGIN
            SET @sqlString = 'IF EXISTS (SELECT key_name FROM sys.openkeys WHERE key_name = ''' + @env_key_name +''') ' 
                  + 'CLOSE SYMMETRIC KEY '+ @env_key_name
            EXECUTE sp_executesql @sqlString
        END
        
        IF (@project_key_name <> '')
        BEGIN
            SET @sqlString = 'IF EXISTS (SELECT key_name FROM sys.openkeys WHERE key_name = ''' + @project_key_name +''') ' 
                  + 'CLOSE SYMMETRIC KEY '+ @project_key_name
            EXECUTE sp_executesql @sqlString
        END;
                
        
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        IF (@env_key_name <> '')
        BEGIN
            SET @sqlString = 'IF EXISTS (SELECT key_name FROM sys.openkeys WHERE key_name = ''' + @env_key_name +''') ' 
                  + 'CLOSE SYMMETRIC KEY '+ @env_key_name
            EXECUTE sp_executesql @sqlString
        END;
        
        IF (@project_key_name <> '')
        BEGIN
            SET @sqlString = 'IF EXISTS (SELECT key_name FROM sys.openkeys WHERE key_name = ''' + @project_key_name +''') ' 
                  + 'CLOSE SYMMETRIC KEY '+ @project_key_name
            EXECUTE sp_executesql @sqlString
        END;
        
        THROW;
    END CATCH
    
    RETURN 0    
            
