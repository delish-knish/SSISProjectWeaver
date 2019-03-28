
CREATE PROCEDURE [catalog].[revoke_permission]
    @object_type SMALLINT,
    @object_id BIGINT,
    @principal_id INTEGER,
    @permission_type SMALLINT
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
    
    DECLARE @ret INTEGER
    DECLARE @is_role BIT
    DECLARE @sid [internal].[adt_sid]
	    
    
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
        EXEC @ret = internal.check_permission_parameters
          @object_type,
          @object_id,
          @principal_id,
          @permission_type,
          @is_role OUTPUT
        
        IF @ret<>0  
           RETURN 1

        SELECT @sid = USER_SID(@principal_id)
		        
        IF @object_type = 1
        BEGIN
            
        DELETE FROM [internal].[folder_permissions]
        WHERE
               [object_id] = @object_id
           AND [sid] = @sid
           AND [permission_type] = @permission_type                                             
        END
        ELSE IF @object_type = 2
        BEGIN
            
        DELETE FROM [internal].[project_permissions]
        WHERE
               [object_id] = @object_id
           AND [sid] = @sid
           AND [permission_type] = @permission_type                                             
        END
        ELSE IF @object_type = 3
        BEGIN
            
        DELETE FROM [internal].[environment_permissions]
        WHERE
               [object_id] = @object_id
           AND [sid] = @sid
           AND [permission_type] = @permission_type                                             
        END
        ELSE
        BEGIN
            
        DELETE FROM [internal].[operation_permissions]
        WHERE
               [object_id] = @object_id
           AND [sid] = @sid
           AND [permission_type] = @permission_type                                             
        END
        
        
        
        
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
        RETURN 0
    END TRY
    
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        THROW
    END CATCH
END
