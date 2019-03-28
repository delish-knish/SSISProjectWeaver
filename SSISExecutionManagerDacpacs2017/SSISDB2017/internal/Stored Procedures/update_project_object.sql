
CREATE PROCEDURE [internal].[update_project_object]
        @project_id              bigint,
        @version_id              bigint,
        @object_data             varbinary(MAX)
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON

    DECLARE @result bit
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
        RAISERROR(27109 , 16 , 1, @project_id) WITH NOWAIT
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
            
        EXEC [internal].[update_object_versions]
            @project_id
            ,@version_id
            ,@object_data
            ,@KEY
            ,@IV
            ,@encryption_algorithm
        
        RETURN 0
    END TRY
    BEGIN CATCH
        
        SET @sqlString = 'IF EXISTS (SELECT key_name FROM sys.openkeys WHERE key_name = ''' + @key_name +''') ' 
                    + 'CLOSE SYMMETRIC KEY '+ @key_name
        EXECUTE sp_executesql @sqlString;
        THROW        
    END CATCH   
