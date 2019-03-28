
CREATE PROCEDURE [catalog].[delete_project]
        @folder_name    nvarchar(128),
        @project_name   nvarchar(128)
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
            RAISERROR(27123, 16, 2) WITH NOWAIT
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
            RAISERROR(27123, 16, 2) WITH NOWAIT
            RETURN 1
    END
    
    DECLARE @result bit
    
    IF (@folder_name IS NULL OR @project_name IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
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
        DECLARE @project_id bigint;
        EXECUTE AS CALLER
            SET @project_id = (SELECT projs.[project_id]
                                    FROM [catalog].[projects] projs WITH (TABLOCKX) INNER JOIN [catalog].[folders] fld  
                                    ON projs.[folder_id] = fld.[folder_id]             
                                    AND projs.[name] = @project_name
                                    AND fld.name = @folder_name);
        REVERT
        IF @project_id IS NULL
        BEGIN
            RAISERROR(27109 , 16 , 1, @project_name) WITH NOWAIT    
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
        END

        DELETE FROM [internal].[projects] WHERE [project_id] = @project_id
        IF @@ROWCOUNT = 0
        BEGIN
             RAISERROR(27113, 16, 4, N'projects') WITH NOWAIT     
        END
        
        
  
        
        DELETE FROM [internal].[object_versions]
            WHERE [object_id] = @project_id AND [object_type] = 20
        IF @@ROWCOUNT = 0
        BEGIN
             RAISERROR(27113, 16, 4, N'object_versions') WITH NOWAIT     
        END 
        
     
          
     
        DECLARE @sqlString    nvarchar(1024)
        DECLARE @key_name               [internal].[adt_name]
        DECLARE @certificate_name     [internal].[adt_name]
        
        
    SET @key_name = 'MS_Enckey_Proj_'+CONVERT(varchar,@project_id)
    SET @certificate_name = 'MS_Cert_Proj_'+CONVERT(varchar,@project_id)
    SET @sqlString = 'IF EXISTS (SELECT name FROM sys.symmetric_keys WHERE name = ''' + @key_name +''') '
        +'DROP SYMMETRIC KEY '+ @key_name
        EXECUTE sp_executesql @sqlString
    SET @sqlString = 'IF EXISTS (select name from sys.certificates WHERE name = ''' + @certificate_name +''') '
        +'DROP CERTIFICATE '+ @certificate_name
        EXECUTE sp_executesql @sqlString  
        
        DELETE FROM [internal].[catalog_encryption_keys]
        WHERE key_name = @key_name
    
    
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
