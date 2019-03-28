
CREATE PROCEDURE [internal].[get_updatedpackages]
    @project_version_lsn bigint,
    @project_name       nvarchar(128),
    @folder_name       nvarchar(128)
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON
    
    DECLARE @result             bit
    DECLARE @project_id         bigint
    
    EXECUTE AS CALLER 
        SELECT @project_id = projs.[project_id]
        FROM [catalog].[projects] projs INNER JOIN [catalog].[folders] fds
        ON projs.[folder_id] = fds.[folder_id] 
        WHERE fds.[name] = @folder_name AND projs.[name] = @project_name
    REVERT
        
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
     
    DECLARE @sqlString              nvarchar(1024)
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
    DECLARE @encryption_algorithm   nvarchar(255)
    DECLARE @KEY                    varbinary(8000)
    DECLARE @IV                     varbinary(8000)
    
    SET @key_name = 'MS_Enckey_Proj_'+CONVERT(varchar,@project_id)
    SET @certificate_name = 'MS_Cert_Proj_'+CONVERT(varchar,@project_id)
    
    BEGIN TRY       
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
        
        SET @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString

        SELECT [name], [package_data] FROM [internal].[get_package_data](@encryption_algorithm, @KEY, @IV, @project_version_lsn, @project_id)

        RETURN 0
    END TRY
    BEGIN CATCH
        
        SET @sqlString = 'IF EXISTS (SELECT key_name FROM sys.openkeys WHERE key_name = ''' + @key_name +''') ' 
                    + 'CLOSE SYMMETRIC KEY '+ @key_name
        EXECUTE sp_executesql @sqlString;
        THROW
    END CATCH
