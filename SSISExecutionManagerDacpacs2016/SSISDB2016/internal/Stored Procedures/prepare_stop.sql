CREATE PROCEDURE [internal].[prepare_stop]
        @operation_id bigint,              
        @process_id   int   output,              
        @operation_guid UniqueIdentifier output,  
        @stop_id    bigint output           
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
            RAISERROR(27123, 16, 11) WITH NOWAIT
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
            RAISERROR(27123, 16, 11) WITH NOWAIT
            RETURN 1
    END
       
    DECLARE @operation_type smallint
    DECLARE @return_value int
    DECLARE @status int
    DECLARE @object_id bigint
    DECLARE @object_name nvarchar(260)
    
    INSERT INTO [internal].[operations] (
        [operation_type],  
        [created_time], 
        [object_type],
        [object_id],
        [object_name],
        [status], 
        [start_time],
        [caller_sid], 
        [caller_name]
        )
    VALUES (
        202,
        SYSDATETIMEOFFSET(),
        20,
        NULL,                     
        NULL,                     
        2,      
        SYSDATETIMEOFFSET(),
        @caller_sid,            
        @caller_name            
        )
            
    SET @stop_id = SCOPE_IDENTITY()

    EXECUTE AS CALLER
        EXEC @return_value = [internal].[init_object_permissions] 
                4, @stop_id, @caller_id 
    REVERT            
    IF @return_value <> 0
    BEGIN
        
        RAISERROR(27153, 16, 1) WITH NOWAIT
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
        SELECT @operation_guid = [operation_guid],
               @process_id = [process_id],
               @status = [status],
               @object_id = [object_id],
               @object_name = [object_name],
               @operation_type = [operation_type]
        FROM   [internal].[operations] 
        WHERE  [operation_id] = @operation_id AND ([status] = 2 OR [status] = 8)
        AND ([operation_type] = 200 OR [operation_type] = 301
            OR [operation_type] = 300) 
            
        IF @operation_guid IS NULL OR @object_id IS NULL
        BEGIN
            RAISERROR(27124, 16 , 1, @operation_id) WITH NOWAIT
        END
        
        IF @status = 8
        BEGIN
            RAISERROR(27126, 16 , 1) WITH NOWAIT
        END
        
        IF @process_id IS NULL
        BEGIN
            RAISERROR(27125, 16 , 1) WITH NOWAIT
        END
        
        
        DECLARE @permission_ret bit
        EXECUTE AS CALLER
           SET @permission_ret = [internal].[check_permission]
           (
              4,
              @operation_id,      
              2
           )
        REVERT
        
        IF (@permission_ret = 0)
        BEGIN
            RAISERROR(27143, 16, 6, @operation_id) WITH NOWAIT
        END
        
        
        EXECUTE AS CALLER
           SET @permission_ret = [internal].[check_permission]
           (
              4,
              @operation_id,      
              1
           )
        REVERT
        
        IF (@permission_ret = 0)
        BEGIN
            RAISERROR(27143, 16, 6, @operation_id) WITH NOWAIT
        END
        
        
        UPDATE [internal].[operations]
            SET status = 8
        WHERE operation_id = @operation_id
            
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR(27112, 16, 7) WITH NOWAIT
        END
        
        UPDATE [internal].[operations]
            SET [object_id] = @object_id,
                [object_name] = @object_name
        WHERE operation_id = @stop_id
        
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR(27112, 16, 7) WITH NOWAIT
        END
         
        
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        UPDATE [internal].[operations]
            SET [status] = 4,
                [end_time] = SYSDATETIMEOFFSET()
        WHERE operation_id = @stop_id;              
        THROW;
    END CATCH
    RETURN 0
