
CREATE PROCEDURE [internal].[get_execution_property_override_values]
        @execution_id       bigint         
WITH EXECUTE AS 'AllSchemaOwner'
AS 
    SET NOCOUNT ON
    DECLARE @result int
    
    DECLARE @sqlString              nvarchar(1024)
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
    DECLARE @encryption_algorithm   nvarchar(255)
    DECLARE @server_operation_encryption_level int
    DECLARE @project_id bigint
    
    IF (@execution_id IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 1) WITH NOWAIT 
        RETURN 1 
    END   

    IF @execution_id <= 0
    BEGIN
        RAISERROR(27101, 16 , 1, N'execution_id') WITH NOWAIT
        RETURN 1;
    END
    
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
        RETURN 1
    END  
    SELECT @server_operation_encryption_level = CONVERT(int,property_value)  
        FROM [catalog].[catalog_properties]
        WHERE property_name = 'SERVER_OPERATION_ENCRYPTION_LEVEL'

    IF @server_operation_encryption_level NOT in (1, 2)        
    BEGIN
        RAISERROR(27163    ,16,1,'SERVER_OPERATION_ENCRYPTION_LEVEL') WITH NOWAIT
        RETURN 1
    END  
    
    SELECT @project_id = [object_id] FROM [internal].[operations]
        WHERE [operation_id] = @execution_id

    
    
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
        
        SELECT [property_path],
               [property_value]
        FROM internal.[execution_property_override_values]
        WHERE [execution_id] = @execution_id 
              AND [sensitive] = 0
        UNION
        SELECT [property_path],
               CONVERT(NVARCHAR, DECRYPTBYKEY([sensitive_property_value])) AS property_value
        FROM internal.[execution_property_override_values]
        WHERE [execution_id] = @execution_id 
              AND [sensitive] = 1
         
        SET @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString             
        
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        SET @sqlString = 'IF EXISTS (SELECT key_name FROM sys.openkeys WHERE key_name = ''' + @key_name +''') ' 
                    + 'CLOSE SYMMETRIC KEY '+ @key_name
        EXECUTE sp_executesql @sqlString;
        THROW;
    END CATCH
     
    RETURN 0       
