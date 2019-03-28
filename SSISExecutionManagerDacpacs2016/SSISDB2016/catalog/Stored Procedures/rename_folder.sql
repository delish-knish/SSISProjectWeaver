
CREATE PROCEDURE [catalog].[rename_folder]
    @old_name NVARCHAR(128),
    @new_name NVARCHAR(128)
AS
BEGIN
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
    
    
    IF (IS_MEMBER('ssis_admin') = 0)
        AND (IS_SRVROLEMEMBER('sysadmin') = 0)
    BEGIN
        RAISERROR(27188,16,1) WITH NOWAIT
        RETURN 1
    END
    
    IF (@old_name IS NULL) OR (@new_name IS NULL)
    BEGIN
        RAISERROR(27189,16,1) WITH NOWAIT
        RETURN 1
    END
    
    IF [internal].[is_valid_name](@new_name) = 0
    BEGIN
        RAISERROR(27199,16,1,@new_name) WITH NOWAIT
        RETURN 1
    END
    
    
    IF @new_name = @old_name
    BEGIN
        RETURN 0
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
        IF NOT EXISTS 
        (
            SELECT [name]
            FROM [internal].[folders]
            WHERE [name] = @old_name
        )
        BEGIN
            RAISERROR(27104,16,1,@old_name) WITH NOWAIT
            RETURN 1
        END
        
        IF EXISTS 
        (
            SELECT [name]
            FROM [internal].[folders]
            WHERE [name] = @new_name
        )
        BEGIN
            RAISERROR(27129,16,1,@new_name) WITH NOWAIT
            RETURN 1
        END
        
        UPDATE [internal].[folders]
        SET [name] = @new_name
        WHERE [name] = @old_name
        
        IF @@ROWCOUNT = 0
        BEGIN
             RAISERROR(27112, 16, 10, N'folders') WITH NOWAIT
             RETURN 1
        END
        ELSE 
        BEGIN
            
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
            RETURN 0
        END
    END TRY
     
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        THROW
    END CATCH
END
