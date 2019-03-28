
CREATE PROCEDURE [catalog].[restore_project]
        @folder_name            nvarchar(128),
        @project_name           nvarchar(128),
        @object_version_lsn     bigint
AS
    SET NOCOUNT ON
    
    DECLARE @version_project_id bigint
    DECLARE @old_version_id bigint
    DECLARE @start_time datetimeoffset
    DECLARE @operation_id bigint
    DECLARE @return_value int
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
    
    IF (@folder_name IS NULL OR @project_name IS NULL OR @object_version_lsn IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1 
    END
        
    SET @start_time = SYSDATETIMEOFFSET()
    
    EXEC @return_value = [internal].[insert_operation] 
                    106, 
                    @start_time,    
                    20,             
                    NULL,             
                    @project_name,
                    2,                                  
                    @start_time,    
                    null,           
                    @caller_sid,    
                    @caller_name,   
                    null,           
                    null,           
                    null,           
                    @operation_id OUTPUT  
     
     IF @return_value <> 0
        RETURN 1

    EXEC @return_value = [internal].[init_object_permissions] 4, @operation_id, @caller_id
    IF @return_value <> 0
    BEGIN
        RAISERROR(27153, 16, 1) WITH NOWAIT
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
                                FROM [catalog].[projects] projs INNER JOIN [catalog].[folders] fld
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
        
        UPDATE [internal].[operations] SET [object_id] = @project_id
            WHERE [operation_id] = @operation_id
        IF @@ROWCOUNT <> 1
        BEGIN
            RAISERROR(27112, 16, 1, N'operations') WITH NOWAIT
        END
        
        SET @version_project_id = (SELECT [object_id] FROM [internal].[object_versions]
                                       WHERE [object_type] = 20 
                                       AND [object_version_lsn] = @object_version_lsn
                                       AND [object_status] = 'C')
                                       
        IF @version_project_id IS NULL OR @version_project_id <> @project_id
        BEGIN
            RAISERROR(27179, 16 , 1) WITH NOWAIT
        END 
        
        
        SET @old_version_id = (SELECT [object_version_lsn] FROM [internal].[projects]
                                       WHERE [project_id] = @project_id)
        
        
        IF @old_version_id = @object_version_lsn
        BEGIN
            RAISERROR (27155, 16,1)
        END
        
        ELSE
        BEGIN    
            UPDATE [internal].[projects] SET [object_version_lsn] = @object_version_lsn
                WHERE [project_id] = @project_id
            
            IF @@ROWCOUNT <> 1
            BEGIN
                RAISERROR(27112, 16, 1, N'projects') WITH NOWAIT
            END
             
            UPDATE [internal].[object_versions]
                SET [restored_by] = @caller_name, [last_restored_time] = SYSDATETIMEOFFSET()
                WHERE [object_version_lsn] = @object_version_lsn
            IF @@ROWCOUNT <> 1
            BEGIN
                RAISERROR(27112, 16, 1, N'object_versions') WITH NOWAIT
            END;
            
            
            WITH ExistingValue( [object_type], [object_name], [parameter_name],
                [parameter_data_type], [required], [sensitive], [default_value], [sensitive_default_value],
                [value_type], [value_set], [referenced_variable_name])
            AS 
               (SELECT [object_type],
                       [object_name],
                       [parameter_name],
                       [parameter_data_type],
                       [required],
                       [sensitive],
                       [default_value],
                       [sensitive_default_value],
                       [value_type],
                       [value_set],
                       [referenced_variable_name]
                FROM [internal].[object_parameters]
                WHERE  [project_id] = @project_id AND [project_version_lsn] = @old_version_id)
            UPDATE [internal].[object_parameters]
                SET [default_value] = e.[default_value],
                    [sensitive_default_value] = e.[sensitive_default_value],
                    [value_type] = e.[value_type],
                    [value_set] = e.[value_set],
                    [referenced_variable_name] = e.[referenced_variable_name]
                FROM [internal].[object_parameters] AS params
                INNER JOIN ExistingValue e ON
                e.[parameter_data_type] = params.[parameter_data_type] 
                AND e.[parameter_name] = params.[parameter_name] COLLATE SQL_Latin1_General_CP1_CS_AS
                AND e.[sensitive] = params.[sensitive] AND e.[object_type] = params.[object_type]
                AND e.[object_name] = params.[object_name] AND e.[required] = params.[required]
                WHERE params.[project_id] = @project_id AND params.[project_version_lsn] = @object_version_lsn
            
               
            DECLARE @client_language nvarchar(256)
            DECLARE @server_language nvarchar(256)
    
            SET @client_language = @@LANGUAGE
            SELECT @server_language = [name] FROM sys.syslanguages WHERE [lcid] = SERVERPROPERTY('LCID')
            SET LANGUAGE @server_language
            
            
            DECLARE @message_start nvarchar(1024)
            DECLARE @message_complete nvarchar(1024)
            
            
            SET @message_start = FORMATMESSAGE (27151, @project_name ,@old_version_id)
            SET @message_complete = FORMATMESSAGE (27152, @project_name ,@object_version_lsn)
            
            
            SET LANGUAGE @client_language
            
            EXEC @return_value = [internal].[append_operation_message] 
                                    @operation_id,
                                    70,
                                    @start_time,
                                    10,
                                    @message_start,
                                    null
            IF @return_value <> 0
            BEGIN
                RAISERROR(27169, 16, 1) WITH NOWAIT
            END
                                   
            EXEC @return_value = [internal].[append_operation_message] 
                                    @operation_id,
                                    70,
                                    @start_time,
                                    10,
                                    @message_complete,
                                    null
            IF @return_value <> 0
            BEGIN
                RAISERROR(27169, 16, 1) WITH NOWAIT
            END                           
        END               
        
        UPDATE [internal].[operations] SET 
            [end_time]  = SYSDATETIMEOFFSET(),
            [status]    = 7
            WHERE operation_id    = @operation_id;                           
                                  
        
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                              
        
        UPDATE [internal].[operations] SET 
            [end_time]  = SYSDATETIMEOFFSET(),
            [status]    = 4
            WHERE operation_id    = @operation_id;                 
        THROW 
    END CATCH
    
    RETURN 0    
    
