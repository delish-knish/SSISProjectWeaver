
CREATE PROCEDURE [catalog].[startup]
WITH EXECUTE AS 'AllSchemaOwner'
AS 
    SET NOCOUNT ON
    DECLARE @operation_id  bigint
    DECLARE @caller_name   nvarchar(256)
    DECLARE @caller_sid    varbinary(85)
    DECLARE @permission_denied smallint
    
    EXECUTE AS CALLER                       
        SET @caller_name =  SUSER_NAME()
        SET @caller_sid =   SUSER_SID()
        SET @permission_denied = 0
        
        
        IF (IS_MEMBER('ssis_admin') <> 1 AND IS_MEMBER('dbo') <> 1
               AND IS_SRVROLEMEMBER('sysadmin') <> 1) AND IS_MEMBER('ssis_failover_monitoring_agent') <> 1
        BEGIN
            SET @permission_denied = 1
        END
    REVERT
    
    IF (@permission_denied = 1)
    BEGIN
        RAISERROR(27219, 16, 1) WITH NOWAIT
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
        1,
        SYSDATETIMEOFFSET(),
        NULL,
        NULL,                     
        NULL,                     
        1,      
        SYSDATETIMEOFFSET(),
        @caller_sid,            
        @caller_name            
        )

    SET @operation_id = SCOPE_IDENTITY();

    DECLARE @ret_val int;
    
    DECLARE @marked_ops TABLE(marked_op_id bigint, marked_op_type smallint, marked_op_status int);

    
    BEGIN TRY

         
        UPDATE [internal].[operations] 
        SET [status] = 6,
        [end_time] = SYSDATETIMEOFFSET()
        OUTPUT DELETED.operation_id, DELETED.operation_type, DELETED.status INTO @marked_ops
        WHERE ([operation_type] = 200)
            AND ([status] = 8);


        
        UPDATE ext
        SET ext.[status] = 6,
        ext.[end_time] = SYSDATETIMEOFFSET()
        FROM [internal].[operations] opers INNER JOIN [internal].[extended_operation_info] ext
            ON opers.[operation_id] = ext.[operation_id] 
            WHERE (opers.[status] IN (2, 5))
            AND opers.[operation_type] IN( 301, 300)
            AND ext.[status] NOT IN (7, 3, 6)
            AND opers.[process_id] NOT IN (SELECT process_id FROM [internal].[get_isserver_processes]())


        
        UPDATE [internal].[operations] 
        SET [status] = 6,
        [end_time] = SYSDATETIMEOFFSET()
        OUTPUT DELETED.operation_id, DELETED.operation_type, DELETED.status INTO @marked_ops
        WHERE ([operation_type] IN( 301, 200, 300))
            AND ([status] IN (2, 5))
            AND ([process_id] NOT IN (SELECT process_id FROM [internal].[get_isserver_processes]()) OR [process_id] IS NULL)

        
        UPDATE [internal].[operations] 
        SET [status] = 6,
        [end_time] = SYSDATETIMEOFFSET()
        OUTPUT DELETED.operation_id, DELETED.operation_type, DELETED.status INTO @marked_ops
        WHERE ([operation_type] IN ( 202, 106, 
            1000, 2, 3, 700))
            AND ([status] IN (2, 5))
        
        
        UPDATE [internal].[operations] 
        SET [status] = 6,
        [end_time] = SYSDATETIMEOFFSET()
        OUTPUT DELETED.operation_id, DELETED.operation_type, DELETED.status INTO @marked_ops
        WHERE ([operation_type] IN( 101))
            AND ([status] IN (2, 5))
        
        
        DECLARE @project_id bigint
        DECLARE @sqlString    nvarchar(1024)
        DECLARE @key_name               [internal].[adt_name]
        DECLARE @certificate_name     [internal].[adt_name]
        
        
        
        DECLARE temp_project_cursor CURSOR LOCAL FOR
            SELECT [project_id] FROM [internal].[projects]
            WHERE [object_version_lsn] = -1
        
        OPEN temp_project_cursor
        FETCH NEXT FROM temp_project_cursor INTO @project_id
        WHILE @@FETCH_STATUS = 0
        BEGIN
            
            
    SET @key_name = 'MS_Enckey_Proj_'+CONVERT(varchar,@project_id)
    SET @certificate_name = 'MS_Cert_Proj_'+CONVERT(varchar,@project_id)
    SET @sqlString = 'IF EXISTS (SELECT name FROM sys.symmetric_keys WHERE name = ''' + @key_name +''') '
        +'DROP SYMMETRIC KEY '+ @key_name
        EXECUTE sp_executesql @sqlString
    SET @sqlString = 'IF EXISTS (select name from sys.certificates WHERE name = ''' + @certificate_name +''') '
        +'DROP CERTIFICATE '+ @certificate_name
        EXECUTE sp_executesql @sqlString
            
            DELETE FROM [internal].[catalog_encryption_keys]
                WHERE key_name = @key_name
                
            DELETE FROM [internal].[projects]
                WHERE [object_version_lsn] = -1 
                AND [project_id] = @project_id
            FETCH NEXT FROM temp_project_cursor INTO @project_id             
        END
        CLOSE temp_project_cursor
        DEALLOCATE temp_project_cursor
        
        
        DELETE FROM [internal].[object_versions]
            WHERE [object_status] = 'D'         
        
        
        
        DECLARE @client_language nvarchar(256)
        DECLARE @server_language nvarchar(256)
        
        SET @client_language = @@LANGUAGE
        SELECT @server_language = [name] FROM sys.syslanguages WHERE [lcid] = SERVERPROPERTY('LCID')
        SET LANGUAGE @server_language

        INSERT INTO [internal].[operation_messages] (
            [operation_id],
            [message_type],
            [message_time],
            [message_source_type],
            [message]
            )
        SELECT
            @operation_id,
            110,
            SYSDATETIMEOFFSET(),
            10,
            FORMATMESSAGE (27165, marked_op_id, marked_op_type, marked_op_status)
        FROM @marked_ops
        
        SET LANGUAGE @client_language
        
        UPDATE [internal].[operations]
            SET [status] = 7,
            [end_time] = SYSDATETIMEOFFSET()
            WHERE [operation_id] = @operation_id; 
        
    END TRY
    BEGIN CATCH
        
        IF (CURSOR_STATUS('local', 'temp_project_cursor') = 1 
            OR CURSOR_STATUS('local', 'temp_project_cursor') = 0)
        BEGIN
            CLOSE temp_project_cursor
            DEALLOCATE temp_project_cursor            
        END
        
        EXEC [internal].[insert_message_caught] @operation_id;
        UPDATE [internal].[operations]
            SET [status] = 4,
            [end_time] = SYSDATETIMEOFFSET()
            WHERE [operation_id] = @operation_id; 
        RETURN 1
    END CATCH
    
    RETURN 0

