
CREATE PROCEDURE [catalog].[rename_environment]
        @folder_name        nvarchar(128),                  
        @environment_name   nvarchar(128),                  
        @new_environment_name nvarchar(128)                 
AS
    SET NOCOUNT ON
    
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
            RAISERROR(27123, 16, 4) WITH NOWAIT
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
            RAISERROR(27123, 16, 4) WITH NOWAIT
            RETURN 1
    END
       
    IF (@folder_name IS NULL OR @environment_name IS NULL OR @new_environment_name IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1 
    END
    
    IF [internal].[is_valid_name](@new_environment_name) = 0
    BEGIN
        RAISERROR(27142,16,1, @new_environment_name) WITH NOWAIT
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
    
        IF EXISTS (SELECT env.[environment_name] FROM 
                        [internal].[environments] env INNER JOIN [internal].[folders] fld
                        ON env.[folder_id] = fld.[folder_id] AND 
                        env.[environment_name] = @new_environment_name AND 
                        fld.[name] = @folder_name )
           BEGIN
                RAISERROR(27157 , 16 , 1, @environment_name) WITH NOWAIT               
           END
    
        UPDATE [internal].[environments] SET environment_name = @new_environment_name 
            WHERE environment_id = @environment_id       
        IF @@ROWCOUNT <> 1
        BEGIN
            RAISERROR(27112, 16, 1, N'environments') WITH NOWAIT
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
