CREATE PROCEDURE [catalog].[remove_data_tap]
        @data_tap_id             bigint
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
    
    DECLARE @execution_id bigint

    SELECT @execution_id = [execution_id]
    FROM [catalog].[execution_data_taps]
    WHERE [data_tap_id] = @data_tap_id

    IF (@execution_id is null)
    BEGIN
        RAISERROR(27215, 16, 1, @data_tap_id) WITH NOWAIT
        RETURN 1
    END

    IF [internal].[check_permission] 
    (
        4,
        @execution_id,
        2
    ) = 0
    BEGIN
        RAISERROR(27143, 16, 5, @execution_id) WITH NOWAIT
        RETURN 1     
    END

    DECLARE @execution_status int
    SELECT @execution_status = [status] FROM [internal].[operations] WHERE [operation_id] = @execution_id
    IF (@execution_status != 1)
    BEGIN
        RAISERROR(27212, 16, 1) WITH NOWAIT
        RETURN 1 
    END

    DELETE FROM [internal].[execution_data_taps] WHERE [data_tap_id] = @data_tap_id

    RETURN 0
