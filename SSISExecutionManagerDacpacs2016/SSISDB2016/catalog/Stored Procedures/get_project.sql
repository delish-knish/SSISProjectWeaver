CREATE PROCEDURE [catalog].[get_project]
        @folder_name  nvarchar(128),
        @project_name nvarchar(128)
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
    
    DECLARE @project_version_lsn    bigint
    DECLARE @project_id             bigint
    DECLARE @project_stream         varbinary(MAX)
    DECLARE @return_value           bigint
    
    IF (@folder_name IS NULL OR @project_name IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 1) WITH NOWAIT 
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
        SELECT @project_version_lsn = proj.[object_version_lsn], @project_id = proj.project_id
                FROM [catalog].[projects] proj INNER JOIN
                [catalog].[folders] fd ON proj.folder_id = fd.folder_id WHERE
                fd.name = @folder_name AND proj.name = @project_name
        
        IF (@project_version_lsn IS NULL OR @project_version_lsn < 0 OR
                @project_id IS NULL OR @project_id < 0)
        BEGIN
            RAISERROR(27109, 16, 1, @project_name) WITH NOWAIT
        END
        
        EXEC @return_value = [internal].[get_project_internal] 
                                 @project_version_lsn, @project_id, @project_name
        IF @return_value <> 0
        BEGIN
            RAISERROR(27170, 16, 1) WITH NOWAIT
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
