CREATE PROCEDURE [catalog].[add_data_tap_by_guid]
        @execution_id             bigint,
        @dataflow_task_guid       uniqueidentifier,
        @dataflow_path_id_string  nvarchar(4000),
        @data_filename            nvarchar(4000),
        @max_rows                 int = null,
        @data_tap_id              bigint = NULL OUTPUT
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

    DECLARE @rowsNum int
    IF (@max_rows is null or @max_rows < 0)
    BEGIN
        SELECT @rowsNum = -1
    END
    ELSE
    BEGIN
        SELECT @rowsNum = @max_rows
    END

    IF NOT EXISTS (SELECT [execution_id] FROM [internal].[execution_info] WHERE [execution_id] = @execution_id)
    BEGIN
        RAISERROR(27103 , 16, 1, @execution_id) WITH NOWAIT
        RETURN 1 
    END

    DECLARE @execution_status int
    SELECT @execution_status = [status] FROM [catalog].[operations] WHERE [operation_id] = @execution_id
    IF (@execution_status != 1)
    BEGIN
        RAISERROR(27212, 16, 1) WITH NOWAIT
        RETURN 1 
    END

    IF EXISTS (SELECT [data_tap_id] 
               FROM [internal].[execution_data_taps] 
               WHERE [execution_id] = @execution_id 
                   AND [dataflow_task_guid] = @dataflow_task_guid 
                   AND [dataflow_path_id_string] = @dataflow_path_id_string COLLATE SQL_Latin1_General_CP1_CS_AS)
    BEGIN
        DECLARE @dataflow_task_guid_string nvarchar(38)
        SET @dataflow_task_guid_string = CONVERT(nvarchar(38), @dataflow_task_guid)
        RAISERROR(27214, 16, 1, @dataflow_task_guid_string,@execution_id) WITH NOWAIT
        RETURN 1
    END

    INSERT INTO [internal].[execution_data_taps]
           ([execution_id],
            [dataflow_task_guid],
            [dataflow_path_id_string],
            [max_rows],
            [filename])
     VALUES(@execution_id,                             
            @dataflow_task_guid,                                                            
            @dataflow_path_id_string,
            @rowsNum,
            @data_filename
           )
    SET @data_tap_id = SCOPE_IDENTITY()
    RETURN 0
