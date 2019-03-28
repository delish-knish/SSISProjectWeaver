
CREATE PROCEDURE [catalog].[create_environment]
        @folder_name        nvarchar(128),                  
        @environment_name   nvarchar(128),                  
        @environment_description    nvarchar(1024)= NULL    
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON
    
    DECLARE @folder_id bigint
    DECLARE @environment_id bigint
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
    
    IF (@folder_name IS NULL OR @environment_name IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1 
    END
    
    IF [internal].[is_valid_name](@environment_name) = 0
    BEGIN
        RAISERROR(27142, 16, 1, @environment_name ) WITH NOWAIT
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
    
        EXECUTE AS CALLER
            SET @folder_id = (SELECT [folder_id] FROM [catalog].[folders] WHERE [name] = @folder_name) 
        REVERT
        
        IF @folder_id IS NULL
        BEGIN
            RAISERROR(27104 , 16 , 1, @folder_name) WITH NOWAIT
        END
        
        EXECUTE AS CALLER   
            SET @result =  [internal].[check_permission] 
                (
                    1,
                    @folder_id,
                    100
                 ) 
        REVERT
        
        IF @result = 0
        BEGIN
            RAISERROR(27209 , 16 , 1, @folder_name) WITH NOWAIT    
        END
         
        IF EXISTS(SELECT env.[environment_name] 
                      FROM [internal].[folders] fld INNER JOIN [internal].[environments] env
                      ON fld.[folder_id] = env.[folder_id] AND 
                      fld.[name] = @folder_name   AND 
                      env.[environment_name] = @environment_name)
        BEGIN
            RAISERROR(27157 , 16 , 1, @environment_name) WITH NOWAIT
        END
    
        INSERT INTO [internal].[environments] 
            VALUES (@environment_name, @folder_id, @environment_description, @caller_sid, @caller_name, SYSDATETIMEOFFSET())
            
        SET @environment_id = SCOPE_IDENTITY() 
       
        
        
        DECLARE @sqlString    nvarchar(1024)
        DECLARE @key_name               [internal].[adt_name]
        DECLARE @certificate_name       [internal].[adt_name]
        DECLARE @encryption_algorithm   nvarchar(255)
        
        SET @encryption_algorithm = (SELECT [internal].[get_encryption_algorithm]())
        
        IF @encryption_algorithm IS NULL
        BEGIN
            RAISERROR(27156, 16, 1, 'ENCRYPTION_ALGORITHM') WITH NOWAIT
        END
        
        
        SET @key_name = 'MS_Enckey_Env_'+CONVERT(varchar,@environment_id)
        SET @certificate_name = 'MS_Cert_Env_'+CONVERT(varchar,@environment_id)
        
        SET @sqlString = 'CREATE CERTIFICATE ' + @certificate_name + ' WITH SUBJECT = ''ISServerCertificate'''
        
        IF  NOT EXISTS (SELECT [name] FROM [sys].[certificates] WHERE [name] = @certificate_name)
            EXECUTE sp_executesql @sqlString 
        
        SET @sqlString = 'CREATE SYMMETRIC KEY ' + @key_name +' WITH ALGORITHM = ' 
                            + @encryption_algorithm + ' ENCRYPTION BY CERTIFICATE ' + @certificate_name
        
        IF  NOT EXISTS (SELECT [name] FROM [sys].[symmetric_keys] WHERE [name] = @key_name)
            EXECUTE sp_executesql @sqlString 
        
        
        DECLARE @retval int
        EXECUTE AS CALLER
            EXEC @retval = [internal].[init_object_permissions] 3, @environment_id, @caller_id
        REVERT
        IF @retval <> 0
        BEGIN
            
            RAISERROR(27153, 16, 1) WITH NOWAIT
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
