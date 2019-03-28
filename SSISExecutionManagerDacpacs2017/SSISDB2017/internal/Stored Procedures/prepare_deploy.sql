CREATE PROCEDURE [internal].[prepare_deploy]
    @folder_name nvarchar(128),
    @project_name nvarchar(128),
    @project_stream varbinary(MAX),
    @operation_id bigint,
    @version_id bigint output,
    @project_id bigint output
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
    
    

    DECLARE @start_time     DATETIMEOFFSET
    DECLARE @return_value   int
    DECLARE @folder_id      bigint
    
    DECLARE @sqlString              nvarchar(1024)
    DECLARE @key_name               [internal].[adt_name]
    DECLARE @certificate_name       [internal].[adt_name]
    DECLARE @encryption_algorithm   nvarchar(255)
    DECLARE @result         bit
    DECLARE @KEY            varbinary(8000)
    DECLARE @IV             varbinary(8000)
    
    EXECUTE AS CALLER
       SET @folder_id = 
            (SELECT [folder_id] FROM [catalog].[folders] WHERE [name] = @folder_name)
    REVERT
       
    BEGIN TRY
                     
        SET @start_time = SYSDATETIMEOFFSET() 
                     
        
        SET @project_id = (SELECT [project_id] FROM [catalog].[projects]
                       WHERE [folder_id] = @folder_id AND [name] = @project_name)
                       
        IF(@project_id IS NULL)
        
        BEGIN
          
            EXECUTE AS CALLER   
                SET @result = [internal].[check_permission] 
                (
                    1,
                    @folder_id,
                    100
                ) 
            REVERT
            
            IF @result = 0                
            BEGIN
                RAISERROR(27206 , 16 , 1, @folder_name) WITH NOWAIT
                RETURN 1        
            END         
            
            IF EXISTS (SELECT [project_id] FROM [internal].[projects]
                    WHERE [folder_id] = @folder_id AND [name] = @project_name)
            BEGIN
                RAISERROR(27118, 16, 1) WITH NOWAIT
                RETURN 1                
            END
            
            EXEC @return_value = [internal].[insert_project] 
                        @folder_id,     
                        @project_name,  
                        null,
                        null,
                        @caller_sid,    
                        @caller_name,   
                        @start_time,
                        @start_time,
                        -1,             
                        'N',            
                        null,                          
                        @project_id OUTPUT  
            IF @return_value <> 0
                RETURN 1;

            
            
            SET @encryption_algorithm = (SELECT [internal].[get_encryption_algorithm]())
        
            IF @encryption_algorithm IS NULL
            BEGIN
                RAISERROR(27156, 16, 1, 'ENCRYPTION_ALGORITHM') WITH NOWAIT
                RETURN 1
            END
            
            SET @key_name = 'MS_Enckey_Proj_'+CONVERT(varchar,@project_id)
            SET @certificate_name = 'MS_Cert_Proj_'+CONVERT(varchar,@project_id)
            
            SET @sqlString = 'CREATE CERTIFICATE ' + @certificate_name + ' WITH SUBJECT = ''ISServerCertificate'''
            
            IF  NOT EXISTS (SELECT [name] FROM [sys].[certificates] WHERE [name] = @certificate_name)
                EXECUTE sp_executesql @sqlString 
            
            SET @sqlString = 'CREATE SYMMETRIC KEY ' + @key_name +' WITH ALGORITHM = ' 
                                + @encryption_algorithm + ' ENCRYPTION BY CERTIFICATE ' + @certificate_name
                                
            IF  NOT EXISTS (SELECT [name] FROM [sys].[symmetric_keys] WHERE [name] = @key_name)
                EXECUTE sp_executesql @sqlString 
            
                        
            
            EXEC @return_value = 
                internal.[create_key_information] @encryption_algorithm, @KEY output, @IV output
            IF(@return_value <> 0)
                RETURN 1;
            
            SET @sqlString = 'OPEN SYMMETRIC KEY ' + @key_name 
                            + ' DECRYPTION BY CERTIFICATE ' + @certificate_name  
            EXECUTE sp_executesql @sqlString 
            
            INSERT INTO [internal].[catalog_encryption_keys]
                VALUES (@key_name, ENCRYPTBYKEY( KEY_GUID(@key_name), @KEY), ENCRYPTBYKEY( KEY_GUID(@key_name), @IV ))
            
            SET @sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
            EXECUTE sp_executesql @sqlString  
            
            EXEC @return_value = [internal].[insert_object_versions] 
                    @project_id,     
                    @project_name,   
                    20, 
                    null,            
                    @caller_name,    
                    @start_time,     
                    null,            
                    null,            
                    @project_stream, 
                    'D',             
                    @KEY,
                    @IV,
                    @encryption_algorithm,
                    @version_id OUTPUT  
            IF @return_value <> 0
                RETURN 1;
            
            
            EXECUTE AS CALLER
                EXEC @return_value = [internal].[init_object_permissions] 
                    2, @project_id, @caller_id 
            REVERT
            IF @return_value <> 0
            BEGIN
                
                RAISERROR(27110, 16, 1) WITH NOWAIT
                RETURN 1
            END            
                 
        END
        
        ELSE  
        BEGIN
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
            
            
            IF EXISTS (SELECT [project_id] FROM [internal].[projects] projs INNER JOIN [internal].[object_versions] vers
                            ON projs.[project_id] = vers.[object_id] WHERE vers.[object_status] = 'D' AND
                             [folder_id] = @folder_id AND [name] = @project_name)
            BEGIN
                RAISERROR(27118, 16, 1) WITH NOWAIT
                RETURN 1            
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
                RETURN 1        
            END
            
            SET @encryption_algorithm = (SELECT [internal].[get_encryption_algorithm]())
        
            IF @encryption_algorithm IS NULL
            BEGIN
                RAISERROR(27156, 16, 1, 'ENCRYPTION_ALGORITHM') WITH NOWAIT
                RETURN 1
            END
            
            SET @key_name = 'MS_Enckey_Proj_'+CONVERT(varchar,@project_id)
            SET @certificate_name = 'MS_Cert_Proj_'+CONVERT(varchar,@project_id)
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
            
            EXEC @return_value = [internal].[insert_object_versions] 
                    @project_id,     
                    @project_name,   
                    20,  
                    null,            
                    @caller_name,    
                    @start_time,     
                    null,            
                    null,            
                    @project_stream, 
                    'D',             
                    @KEY,
                    @IV,
                    @encryption_algorithm,
                    @version_id OUTPUT  
            IF @return_value <> 0
                RETURN 1;                    
        END
        
        UPDATE [internal].[operations] 
            SET [object_id] = @project_id
            WHERE [operation_id] = @operation_id
            
        IF @@ROWCOUNT <> 1
        BEGIN
            RAISERROR(27112, 16, 1, N'operations') WITH NOWAIT
            RETURN 1
        END
           
    END TRY
    BEGIN CATCH 
        UPDATE [internal].[operations] SET 
            [end_time]  = SYSDATETIMEOFFSET(),
            [status]    = 4
            WHERE [operation_id]    = @operation_id;             
        THROW 
    END CATCH
