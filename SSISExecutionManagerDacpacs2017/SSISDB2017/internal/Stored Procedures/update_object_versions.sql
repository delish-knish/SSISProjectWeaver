
CREATE PROCEDURE [internal].[update_object_versions]
        @object_id              bigint,
        @version_id             bigint,
        @object_data            varbinary(MAX), 
        @KEY                    varbinary(8000),
        @IV                     varbinary(8000),
        @algorithm_name         nvarchar(255)
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON
    
    DECLARE @sqlString              nvarchar(1024)
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
    DECLARE @encryption_algorithm   nvarchar(255)
    DECLARE @encrypted_value        varbinary(MAX)
    
    SET @key_name = 'MS_Enckey_Proj_'+CONVERT(varchar,@object_id)
    SET @certificate_name = 'MS_Cert_Proj_'+CONVERT(varchar,@object_id)
    
    IF NOT EXISTS (SELECT name FROM sys.symmetric_keys WHERE name = @key_name )
       OR NOT EXISTS (SELECT name FROM sys.certificates WHERE name = @certificate_name )
    BEGIN
        
        RAISERROR(27172, 16, 1, @object_id) WITH NOWAIT
        RETURN 1
    END
    
    BEGIN TRY
        SET @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name
                            + ' DECRYPTION BY CERTIFICATE ' + @certificate_name
        EXECUTE sp_executesql @sqlString 
        
        SET @encrypted_value = [internal].[encrypt_lob_data](@algorithm_name, @KEY, @IV, @object_data); 
        
        IF @encrypted_value IS NULL
        BEGIN
            RAISERROR(27119, 16, 1, @object_id) WITH NOWAIT
            RETURN 1
        END
    
        SET @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString
            
        UPDATE [internal].[object_versions]
        SET [object_data] = @encrypted_value
        WHERE [object_id] = @object_id AND [object_version_lsn] = @version_id
        
    END TRY  
    BEGIN CATCH
        SET @sqlString = 'IF EXISTS (SELECT key_name FROM sys.openkeys WHERE key_name = ''' + @key_name +''') ' 
                    + 'CLOSE SYMMETRIC KEY '+ @key_name
        EXECUTE sp_executesql @sqlString;        
        THROW
    END CATCH
