
CREATE PROCEDURE [catalog].[set_execution_property_override_value]
        @execution_id       bigint,   
        @property_path      nvarchar(4000), 
        @property_value     nvarchar(max),  
	    @sensitive			bit

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
    DECLARE @id bigint
    DECLARE @sensitive_value varbinary(MAX)
    DECLARE @calculated_property_value nvarchar(MAX)
    DECLARE @return_value           bit = 1
    
    IF (@execution_id IS NULL OR @property_path IS NULL OR @property_value IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 1) WITH NOWAIT 
        RETURN 1 
    END   
    
    IF @execution_id <= 0
    BEGIN
        RAISERROR(27101, 16 , 1, N'execution_id') WITH NOWAIT
        RETURN 1;
    END
    
    DECLARE @sqlString              nvarchar(1024)
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
    DECLARE @encryption_algorithm   nvarchar(255)    
    DECLARE @server_operation_encryption_level int

    
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
            RAISERROR(27225 , 16 , 1) WITH NOWAIT
        END
       
        SELECT @server_operation_encryption_level = CONVERT(int,property_value)  
                FROM [catalog].[catalog_properties]
                WHERE property_name = 'SERVER_OPERATION_ENCRYPTION_LEVEL'

        IF @server_operation_encryption_level NOT in (1, 2)        
        BEGIN
            RAISERROR(27163    ,16,1,'SERVER_OPERATION_ENCRYPTION_LEVEL')
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
            
            SET @sensitive_value = EncryptByKey(KEY_GUID(@key_name),CONVERT(varbinary(MAX),@property_value))
			SET @calculated_property_value = NULL
            
            SET @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString  
		END

		ELSE

		BEGIN
            SET @sensitive_value = NULL
			SET @calculated_property_value = @property_value
		END
            
		IF EXISTS 
		(
			SELECT 1
			FROM [internal].[execution_property_override_values]
			WHERE execution_id = @execution_id
			AND property_path = @property_path
		)
		BEGIN
			UPDATE [internal].[execution_property_override_values]
			SET
				property_value = @calculated_property_value,
				sensitive_property_value = @sensitive_value,
				sensitive = @sensitive
		END

		ELSE

		BEGIN
			INSERT INTO [internal].[execution_property_override_values]
			(
				execution_id,
				property_path,
				sensitive,
				property_value,
				sensitive_property_value
			)
			VALUES
			(
				@execution_id,
				@property_path,
				@sensitive,
				@calculated_property_value,
				@sensitive_value
			)
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
