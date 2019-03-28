
CREATE PROCEDURE [internal].[cleanup_server_log]
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON
    
    DECLARE @enable_clean_operation bit
    
    DECLARE @caller_name nvarchar(256)
    DECLARE @caller_sid  varbinary(85)
    DECLARE @operation_id bigint
    
    EXECUTE AS CALLER
        SET @caller_name =  SUSER_NAME()
        SET @caller_sid =   SUSER_SID()
    REVERT
         
    
    BEGIN TRY
        SELECT @enable_clean_operation = CONVERT(bit, property_value) 
            FROM [catalog].[catalog_properties]
            WHERE property_name = 'OPERATION_CLEANUP_ENABLED'
        
        IF @enable_clean_operation = 1
        BEGIN
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
                2,
                SYSDATETIMEOFFSET(),
                NULL,                     
                NULL,                     
                NULL,                     
                1,      
                SYSDATETIMEOFFSET(),
                @caller_sid,            
                @caller_name            
                ) 
            SET @operation_id = SCOPE_IDENTITY()
            
            
            IF EXISTS (SELECT operation_id FROM [internal].[operations]
                    WHERE [status] IN (2, 5)
                    AND   [operation_id] <> @operation_id )
            BEGIN    
                RAISERROR(27139, 16, 1) WITH NOWAIT
                RETURN 1
            END
            
            IF NOT EXISTS (SELECT [user_access] FROM sys.databases 
                WHERE name = 'SSISDB' and [user_access] = 1 )
            BEGIN
                RAISERROR(27160, 16 , 1, N'cleanup_server_log' ) WITH NOWAIT
                RETURN 1
            END 
            
            DECLARE @rows_affected bigint
            DECLARE @delete_batch_size int

            DECLARE @execution_id bigint
            CREATE TABLE #deleted_ops (operation_id bigint, operation_type smallint)
            DECLARE execution_cursor CURSOR LOCAL FOR SELECT operation_id FROM #deleted_ops  WHERE operation_type = 200

			DECLARE @sqlString_operation_messages_scaleout   nvarchar(1024)
            DECLARE @sqlString_event_messages_scaleout       nvarchar(1024)
            DECLARE @sqlString_event_message_context_scaleout        nvarchar(1024)

            
            SET @delete_batch_size = 1000  
            SET @rows_affected = @delete_batch_size
            
            WHILE (@rows_affected = @delete_batch_size)
            BEGIN
                DELETE TOP (@delete_batch_size)
                    FROM [internal].[operations] 
                    OUTPUT DELETED.operation_id, DELETED.operation_type INTO #deleted_ops
                    WHERE ([operation_type] = 200)
                  
                SET @rows_affected = @@ROWCOUNT
                OPEN execution_cursor
                FETCH NEXT FROM execution_cursor INTO @execution_id
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    SET @sqlString_operation_messages_scaleout = 'delete from [internal].[operation_messages_scaleout] where operation_id = '+CONVERT(varchar,@execution_id)
                    SET @sqlString_event_messages_scaleout = 'delete from [internal].[event_messages_scaleout] where operation_id = '+CONVERT(varchar,@execution_id)
                    SET @sqlString_event_message_context_scaleout  = 'delete from [internal].[event_message_context_scaleout] where operation_id = '+CONVERT(varchar,@execution_id)
                    BEGIN TRY
                        EXECUTE sp_executesql @sqlString_operation_messages_scaleout
                        EXECUTE sp_executesql @sqlString_event_messages_scaleout
                        EXECUTE sp_executesql @sqlString_event_message_context_scaleout
                    END TRY
                    BEGIN CATCH 
                    END CATCH
                    FETCH NEXT FROM execution_cursor INTO @execution_id
                END
                CLOSE execution_cursor
                TRUNCATE TABLE #deleted_ops
                DEALLOCATE execution_cursor
            END
             DROP TABLE #deleted_ops
            
            UPDATE [internal].[operations]
                SET [status] = 7,
                [end_time] = SYSDATETIMEOFFSET()
                WHERE [operation_id] = @operation_id
        END
    END TRY
    BEGIN CATCH
        UPDATE [internal].[operations]
            SET [status] = 4,
            [end_time] = SYSDATETIMEOFFSET()
            WHERE [operation_id] = @operation_id;
        THROW;
    END CATCH
    
    RETURN 0
