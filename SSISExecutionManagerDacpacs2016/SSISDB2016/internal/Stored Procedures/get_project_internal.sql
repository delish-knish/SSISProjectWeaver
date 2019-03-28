
CREATE PROCEDURE [internal].[get_project_internal]
    @project_version_lsn bigint,
    @project_id         bigint,
    @project_name       nvarchar(128)
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON
    
    DECLARE @project_stream     varbinary(MAX)
    DECLARE @result             bit
    
    IF (@project_id IS NULL OR @project_id < 0 
            OR @project_version_lsn IS NULL OR @project_version_lsn < 0)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1 
    END
    
    EXECUTE AS CALLER   
        SET @result = [internal].[check_permission] 
        (
            2,
            @project_id,
            1
        ) 
    REVERT
    IF @result = 0
    BEGIN
        RAISERROR(27109 , 16 , 1, @project_name) WITH NOWAIT
        RETURN 1        
    END
     
    DECLARE @encrypted_value        varbinary(MAX)
    DECLARE @sqlString              nvarchar(1024)
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
    DECLARE @encryption_algorithm  nvarchar(255)
    DECLARE @KEY                    varbinary(8000)
    DECLARE @IV                     varbinary(8000)
    
    SET @key_name = 'MS_Enckey_Proj_'+CONVERT(varchar,@project_id)
    SET @certificate_name = 'MS_Cert_Proj_'+CONVERT(varchar,@project_id)
    
    BEGIN TRY
        SET @encrypted_value = (SELECT [object_data] FROM [internal].[object_versions]
                                    WHERE [object_version_lsn] = @project_version_lsn AND [object_id] = @project_id)
        
        IF @encrypted_value IS NULL
        BEGIN
            RAISERROR(27109 , 16 , 1, @project_name) WITH NOWAIT
            RETURN 1
        END
        
        SET @encryption_algorithm = (SELECT [internal].[get_encryption_algorithm]())
        IF @encryption_algorithm IS NULL
        BEGIN
            RAISERROR(27156, 16, 1, 'ENCRYPTION_ALGORITHM') WITH NOWAIT
            RETURN 1
        END
        
        SET @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name 
                            + ' DECRYPTION BY CERTIFICATE ' + @certificate_name  
        EXECUTE sp_executesql @sqlString 
        
        SELECT @KEY = DECRYPTBYKEY([key]), @IV = DECRYPTBYKEY([IV]) 
            FROM [internal].[catalog_encryption_keys]
            WHERE [key_name] = @key_name
        IF (@KEY IS NULL OR @IV IS NULL)
        BEGIN
            RAISERROR(27117, 16 ,1) WITH NOWAIT
            RETURN 1
        END
                    
        SET @project_stream = [internal].[decrypt_lob_data](@encryption_algorithm, @KEY,@IV,@encrypted_value) 
        
        IF (@project_stream IS NULL)
        BEGIN
            RAISERROR(27117, 16 ,1) WITH NOWAIT
            RETURN 1
        END
    
        SET @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString
        
        SELECT @project_stream AS project_stream
                    
        RETURN 0
    END TRY
    BEGIN CATCH
        
        SET @sqlString = 'IF EXISTS (SELECT key_name FROM sys.openkeys WHERE key_name = ''' + @key_name +''') ' 
                    + 'CLOSE SYMMETRIC KEY '+ @key_name
        EXECUTE sp_executesql @sqlString;
        THROW        
    END CATCH   
