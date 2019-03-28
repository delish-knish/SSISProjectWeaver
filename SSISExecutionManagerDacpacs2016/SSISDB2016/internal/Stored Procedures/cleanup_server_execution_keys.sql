
CREATE PROCEDURE [internal].[cleanup_server_execution_keys]
    @cleanup_flag           int,
    @delete_batch_size      int = 1000
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON
    
    DECLARE @enable_clean_operation bit
    
    DECLARE @caller_name nvarchar(256)
    DECLARE @caller_sid  varbinary(85)
    DECLARE @operation_id bigint
    DECLARE @server_operation_encryption_level int
    
    EXECUTE AS CALLER
        SET @caller_name =  SUSER_NAME()
        SET @caller_sid =   SUSER_SID()
    REVERT
         
    
    BEGIN TRY
        SELECT @enable_clean_operation = CONVERT(bit, property_value) 
            FROM [catalog].[catalog_properties]
            WHERE property_name = 'OPERATION_CLEANUP_ENABLED'

       SELECT @server_operation_encryption_level = CONVERT(int,property_value)
        FROM [catalog].[catalog_properties]
        WHERE property_name = 'SERVER_OPERATION_ENCRYPTION_LEVEL'

        IF @enable_clean_operation <> 1 
            RETURN 0

        IF @cleanup_flag = 1 AND @server_operation_encryption_level = 2
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
            
            DECLARE @key_name               [internal].[adt_name]
            DECLARE @certificate_name       [internal].[adt_name]
            DECLARE @sqlString              nvarchar(1024)
            DECLARE @count int

            IF @delete_batch_size < 1
            BEGIN
                SET @delete_batch_size = 1000
            END

            DECLARE key_cursor CURSOR LOCAL FOR
                SELECT [name] FROM [sys].[symmetric_keys]
                WHERE [name] like 'MS_Enckey_Exec_%'

            DECLARE cert_cursor CURSOR LOCAL FOR
                SELECT [name] FROM [sys].[certificates]
                WHERE [name] like 'MS_Cert_Exec_%'
           
            SET @count = 0
            
            OPEN key_cursor
            FETCH NEXT FROM key_cursor INTO @key_name

            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @sqlString = ' DROP SYMMETRIC KEY ' + @key_name
                BEGIN TRY
                    EXECUTE sp_executesql @sqlString
                END TRY
                BEGIN CATCH
                    
                END CATCH
                SET @count = @count + 1
                IF @count = @delete_batch_size
                    BREAK

                FETCH NEXT FROM key_cursor INTO @key_name
            END
            CLOSE key_cursor
            DEALLOCATE key_cursor

            OPEN cert_cursor
            FETCH NEXT FROM cert_cursor INTO @certificate_name

            SET @count = 0

            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @sqlString = ' DROP CERTIFICATE ' + @certificate_name
                BEGIN TRY
                    EXECUTE sp_executesql @sqlString
                END TRY
                BEGIN CATCH
                    
                END CATCH
                SET @count = @count + 1
                IF @count = @delete_batch_size
                    BREAK
        
                FETCH NEXT FROM cert_cursor INTO @certificate_name
            END

            CLOSE cert_cursor
            DEALLOCATE cert_cursor

            UPDATE [internal].[operations]
                SET [status] = 7,
                [end_time] = SYSDATETIMEOFFSET()
                WHERE [operation_id] = @operation_id
        END
        ELSE IF @cleanup_flag = 2
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

            DECLARE @id                      [internal].[adt_name]

            DECLARE @project_id                    bigint

            DECLARE key_cursor CURSOR LOCAL FOR
                SELECT [name] FROM [sys].[symmetric_keys]
                WHERE [name] like 'MS_Enckey_Proj_Param_%'

            DECLARE cert_cursor CURSOR LOCAL FOR
                SELECT [name] FROM [sys].[certificates]
                WHERE [name] like 'MS_Cert_Proj_Param_%'

            OPEN key_cursor
            FETCH NEXT FROM key_cursor INTO @key_name

            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @id = SubString(@key_name,PATINDEX('%[0-9]%',@key_name),Len(@key_name))
                SET @project_id = CONVERT(int,@id) 
                SET @sqlString = ' DROP SYMMETRIC KEY ' + @key_name
                BEGIN TRY
                    IF @server_operation_encryption_level = 1
                    BEGIN
                        EXECUTE sp_executesql @sqlString
                    END
                    ELSE IF @server_operation_encryption_level = 2
                    BEGIN
                        IF (NOT EXISTS (SELECT [project_id] FROM [internal].[projects]
                            WHERE [project_id] = @project_id)) AND
                            (NOT EXISTS (SELECT [operation_id] FROM [internal].[operations] 
                            WHERE [object_id] = @project_id AND [operation_type] = 200))
                        EXECUTE sp_executesql @sqlString
                    END

                END TRY
                BEGIN CATCH
                    
                END CATCH
                
                FETCH NEXT FROM key_cursor INTO @key_name
            END
            CLOSE key_cursor
            DEALLOCATE key_cursor

            OPEN cert_cursor
            FETCH NEXT FROM cert_cursor INTO @certificate_name

            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @id = SubString(@certificate_name,PATINDEX('%[0-9]%',@certificate_name),Len(@certificate_name))
                SET @project_id = CONVERT(int,@id) 

                SET @sqlString = ' DROP CERTIFICATE ' + @certificate_name
                BEGIN TRY
                    IF @server_operation_encryption_level = 1
                    BEGIN
                        EXECUTE sp_executesql @sqlString
                    END
                    ELSE IF @server_operation_encryption_level = 2
                    BEGIN
                        IF (NOT EXISTS (SELECT [project_id] FROM [internal].[projects]
                            WHERE [project_id] = @project_id)) AND
                            (NOT EXISTS (SELECT [operation_id] FROM [internal].[operations] 
                            WHERE [object_id] = @project_id AND [operation_type] = 200))
                        EXECUTE sp_executesql @sqlString
                    END
                END TRY
                BEGIN CATCH
                    
                END CATCH
        
                FETCH NEXT FROM cert_cursor INTO @certificate_name
            END

            CLOSE cert_cursor
            DEALLOCATE cert_cursor

            UPDATE [internal].[operations]
                SET [status] = 7,
                [end_time] = SYSDATETIMEOFFSET()
                WHERE [operation_id] = @operation_id
        END
    END TRY
    BEGIN CATCH
        
        IF (CURSOR_STATUS('local', 'key_cursor') = 1
            OR CURSOR_STATUS('local', 'key_cursor') = 0)
        BEGIN
            CLOSE key_cursor
            DEALLOCATE key_cursor
        END


        IF (CURSOR_STATUS('local', 'cert_cursor') = 1
            OR CURSOR_STATUS('local', 'cert_cursor') = 0)
        BEGIN
            CLOSE cert_cursor
            DEALLOCATE cert_cursor
        END

        UPDATE [internal].[operations]
            SET [status] = 4,
            [end_time] = SYSDATETIMEOFFSET()
            WHERE [operation_id] = @operation_id;
        THROW;
    END CATCH
    
    RETURN 0
