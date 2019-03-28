
CREATE PROCEDURE [catalog].[set_environment_variable_value]
        @folder_name        nvarchar(128),        
        @environment_name   nvarchar(128),        
        @variable_name      nvarchar(128),        
        @value              sql_variant           
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
            RAISERROR(27123, 16, 8) WITH NOWAIT
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
            RAISERROR(27123, 16, 8) WITH NOWAIT
            RETURN 1
    END
    
    DECLARE @data_type      nvarchar(128)

    DECLARE @sqlString      nvarchar(1024) 
    DECLARE @key_name               [internal].[adt_name] 
    DECLARE @certificate_name       [internal].[adt_name] 
    
    DECLARE @binary_value   varbinary(MAX)
    DECLARE @sensitive      bit
    DECLARE @result bit
    DECLARE @return_value           bit = 1
    
    DECLARE @variable_type nvarchar(128)
    
    IF (@folder_name IS NULL OR @environment_name IS NULL OR
            @variable_name IS NULL OR @value IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1     
    END    
    
    SET @variable_type = CONVERT(nvarchar(128), SQL_VARIANT_PROPERTY(@value, 'BaseType'))
    IF (@variable_type IS NULL)
    BEGIN
        RAISERROR(27159, 16 , 1) WITH NOWAIT 
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
        
        SET @sensitive = (SELECT [sensitive] FROM [internal].[environment_variables]
                                WHERE [environment_id] = @environment_id AND [name] = @variable_name)
        IF (@sensitive IS NULL)
        BEGIN
            RAISERROR(27154 , 16 , 1) WITH NOWAIT  
        END 

        SET @data_type = (SELECT [type] FROM [internal].[environment_variables]
                                WHERE [environment_id] = @environment_id AND [name] = @variable_name)
                                
        EXEC @return_value = [internal].[check_data_type_value] 
            @value, @data_type
     
        IF (@return_value <> 0)         
        
        BEGIN
            RAISERROR(27147, 16 , 1, @data_type) WITH NOWAIT
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
                SET @binary_value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(4000),CONVERT(datetime2, @value)))
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
            
            UPDATE [internal].[environment_variables] 
                SET [sensitive_value] = @binary_value, [base_data_type] = @variable_type
                WHERE [environment_id] = @environment_id AND [name] = @variable_name 
            IF @@ROWCOUNT <> 1
            BEGIN
                RAISERROR(27112, 16, 1, N'environment_variables') WITH NOWAIT
            END            
        END   
        
        ELSE
        BEGIN
            UPDATE [internal].[environment_variables] 
                SET [value] = @value, [base_data_type] = @variable_type
                WHERE [environment_id] = @environment_id AND [name] = @variable_name  
            IF @@ROWCOUNT <> 1
            BEGIN
                RAISERROR(27112, 16, 1, N'environment_variables') WITH NOWAIT
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
