CREATE PROCEDURE [catalog].[create_execution_dump]
    @execution_id       bigint          
AS
    SET NOCOUNT ON;
    DECLARE @return_value int
    
    IF (@execution_id IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 1) WITH NOWAIT 
        RETURN 1 
    END   

    IF @execution_id <= 0
    BEGIN
        RAISERROR(27101, 16 , 1, N'execution_id') WITH NOWAIT
        RETURN 1;
    END
    
    
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
            RAISERROR(27123, 16, 12) WITH NOWAIT
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
            RAISERROR(27123, 16, 12) WITH NOWAIT
            RETURN 1
    END

    DECLARE @process_id bigint
    DECLARE @object_name nvarchar(260)
    SELECT  @process_id = [process_id],
            @object_name = [object_name]
    FROM   [internal].[operations] 
    WHERE  [operation_id] = @execution_id AND [status] = 2 AND [operation_type] = 200

    IF @process_id IS NULL
    BEGIN
        RAISERROR(27218, 16 , 1, @execution_id) WITH NOWAIT
        RETURN 1
    END

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
        205,
        SYSDATETIMEOFFSET(),
        50,
        @execution_id,
        @object_name,
        2,      
        SYSDATETIMEOFFSET(),
        @caller_sid,            
        @caller_name            
        )
    DECLARE @dump_id bigint
    SET @dump_id = SCOPE_IDENTITY()

    BEGIN TRY        
        EXEC @return_value = 
                    [internal].[create_execution_dump_internal]
                            @execution_id
    END TRY
    BEGIN CATCH
        UPDATE [internal].[operations] SET 
               [end_time]  = SYSDATETIMEOFFSET(),
               [status]    = 4,
               [process_id]= @process_id
         WHERE operation_id    = @dump_id;
         THROW
    END CATCH

    DECLARE @status int
    SET @status =
        CASE
            WHEN (@return_value = 0) THEN 7
            ELSE 4
        END

    UPDATE [internal].[operations] SET 
           [end_time]  = SYSDATETIMEOFFSET(),
           [status]    = @status,
           [process_id]= @process_id
     WHERE operation_id    = @dump_id
    RETURN @return_value
