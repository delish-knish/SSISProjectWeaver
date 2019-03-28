
CREATE PROCEDURE [catalog].[create_environment_variable]
        @folder_name        sysname,                  
        @environment_name   nvarchar(128),                  
        @variable_name      nvarchar(128),            
        @data_type          nvarchar(128),            
        @sensitive          bit,                      
        @value              sql_variant,              
        @description        nvarchar(1024)= NULL
WITH EXECUTE AS 'AllSchemaOwner'
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
            RAISERROR(27123, 16, 5) WITH NOWAIT
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
            RAISERROR(27123, 16, 5) WITH NOWAIT
            RETURN 1
    END   
     
    DECLARE @binary_value   varbinary(MAX)
    
    DECLARE @sqlString    nvarchar(1024) 
    DECLARE @key_name               [internal].[adt_name] 
    DECLARE @certificate_name       [internal].[adt_name] 
    DECLARE @variable_type          [nvarchar](128)
    DECLARE @return_value           bit = 1
    
    IF (@folder_name IS NULL OR @environment_name IS NULL 
            OR @variable_name IS NULL OR @data_type IS NULL
            OR @sensitive IS NULL OR @value IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 1) WITH NOWAIT 
        RETURN 1 
    END
    
    IF [internal].[is_valid_name](@variable_name) = 0
    BEGIN
        RAISERROR(27180, 16, 1, @variable_name) WITH NOWAIT
        RETURN 1
    END
    
    IF NOT EXISTS (SELECT [ssis_data_type] FROM [internal].[data_type_mapping]
                  WHERE [ssis_data_type] = @data_type)
    BEGIN
        RAISERROR(27159, 16 , 1) WITH NOWAIT 
        RETURN 1         
    END        
    
    SET @variable_type = CONVERT(nvarchar(128), SQL_VARIANT_PROPERTY(@value, 'BaseType'))
    IF (@variable_type IS NULL)
    BEGIN
        RAISERROR(27159, 16 , 1) WITH NOWAIT 
        RETURN 1   
    END
    
    EXEC @return_value = [internal].[check_data_type_value] 
        @value, @data_type
 
    IF (@return_value <> 0)         
    
    BEGIN
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
           
        IF EXISTS (SELECT [variable_id] FROM [internal].[environment_variables]
                        WHERE [environment_id]= @environment_id AND [name] = @variable_name)
        BEGIN
            RAISERROR(27173 , 16 , 1, @variable_name) WITH NOWAIT   
        END
    
        
        IF (@sensitive = 1)
        BEGIN
            SET @key_name = 'MS_Enckey_Env_'+CONVERT(varchar,@environment_id)
            SET @certificate_name = 'MS_Cert_Env_'+CONVERT(varchar,@environment_id)
            
            SET @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name 
                                + ' DECRYPTION BY CERTIFICATE ' + @certificate_name  
            EXECUTE sp_executesql @sqlString
            
            
            
            
            IF @data_type = 'datetime'
            BEGIN
                SET @binary_value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(4000),CONVERT(datetime2,@value)))
            END
            
            ELSE IF @data_type = 'single' OR @data_type = 'double' OR @data_type = 'decimal'
            BEGIN
                SET @binary_value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(4000),CONVERT(decimal(38,18),@value)))
            END
                        
            ELSE
            BEGIN
                SET @binary_value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(MAX),@value))   
            END
            
            SET @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString    
            
            INSERT INTO  [internal].[environment_variables] ([environment_id], [name], [description], [type], [sensitive], [value], [sensitive_value], [base_data_type])      
                VALUES (@environment_id, @variable_name, @description, @data_type, @sensitive, null, @binary_value, @variable_type)
        END
        
        
        ELSE    
        BEGIN
            INSERT INTO  [internal].[environment_variables] ([environment_id], [name], [description], [type], [sensitive], [value], [sensitive_value], [base_data_type])      
                VALUES (@environment_id, @variable_name, @description, @data_type, @sensitive, @value, null, @variable_type)            
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
    
