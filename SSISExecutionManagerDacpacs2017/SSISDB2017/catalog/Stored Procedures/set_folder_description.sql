
CREATE PROCEDURE [catalog].[set_folder_description]
    @folder_name NVARCHAR(128),
    @folder_description NVARCHAR(MAX)
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
    
    IF @folder_name IS NULL
    BEGIN
        RAISERROR(27189,16,1) WITH NOWAIT
        RETURN 1
    END
    
    UPDATE [internal].[folders]
    SET [description] = @folder_description
    WHERE [name] = @folder_name
        
    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(27104,16,1,@folder_name) WITH NOWAIT
        RETURN 1
    END
    ELSE 
    BEGIN
        RETURN 0
    END
END
