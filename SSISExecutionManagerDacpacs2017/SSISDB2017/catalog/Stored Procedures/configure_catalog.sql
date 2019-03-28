
CREATE PROCEDURE [catalog].[configure_catalog] 
        @property_name           nvarchar(255), 
        @property_value          nvarchar(255)
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

    EXECUTE AS CALLER
        IF ((IS_MEMBER('ssis_admin') <> 1) AND (IS_SRVROLEMEMBER('sysadmin') <> 1))
            BEGIN
               RAISERROR(27140, 16, 1, N'ssis_admin', N'sysadmin') WITH NOWAIT
               RETURN 1 
            END
    REVERT
    
    IF @property_name IS NULL OR @property_value IS NULL
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1 
    END
    
    IF @property_name NOT IN ('ENCRYPTION_ALGORITHM', 'RETENTION_WINDOW', 
            'MAX_PROJECT_VERSIONS', 'VERSION_CLEANUP_ENABLED', 'OPERATION_CLEANUP_ENABLED', 'SERVER_LOGGING_LEVEL','SERVER_CUSTOMIZED_LOGGING_LEVEL','SERVER_OPERATION_ENCRYPTION_LEVEL', 'DEFAULT_EXECUTION_MODE')
    BEGIN
        RAISERROR(27101, 16 , 1, N'property_name') WITH NOWAIT
        RETURN 1
    END
    
    DECLARE @operation_id       bigint
    DECLARE @return_value       int
    DECLARE @status             int
    DECLARE @result             bit
    DECLARE @ret                int
    DECLARE @old_algorithm_name nvarchar(255)
    
    SET @result = 1
    
    INSERT INTO [internal].[operations] (
        [operation_type],
        [created_time],
        [object_type],
        [object_id],
        [object_name] ,
        [status], 
        [start_time],
        [caller_sid], 
        [caller_name]
        )
    VALUES (
        1000,
        SYSDATETIMEOFFSET(),
        NULL,
        NULL,
        @property_name,
        2,
        SYSDATETIMEOFFSET(), 
        @caller_sid,            
        @caller_name  
        )
        
    IF @@ROWCOUNT <> 1
    BEGIN
      RETURN 1;
    END

    SET @operation_id = SCOPE_IDENTITY();
    
    EXECUTE AS CALLER
        EXEC @return_value = [internal].[init_object_permissions] 
                    4, @operation_id, @caller_id 
    REVERT            
    IF @return_value <> 0
    BEGIN
        
        RAISERROR(27153, 16, 1) WITH NOWAIT
        RETURN 1
    END   
    
    
    IF (UPPER(@property_name) = 'ENCRYPTION_ALGORITHM')
    BEGIN
                
        
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

            IF NOT EXISTS (SELECT [user_access] FROM sys.databases 
                WHERE name = 'SSISDB' and [user_access] = 1 )
            BEGIN
                RAISERROR(27162, 16 , 1, N'ENCRYPTION_ALGORITHM' ) WITH NOWAIT
            END
            
            SELECT @old_algorithm_name = property_value
                FROM [internal].[catalog_properties] 
                WHERE property_name = 'ENCRYPTION_ALGORITHM'
            
            SELECT @ret = [internal].[validate_encryption_algorithm](@property_value)
            IF @ret <> 0
            BEGIN
               RAISERROR(27101, 16, 12, N'property_value') WITH NOWAIT
            END
            
            
            
            EXEC @ret = [internal].[configure_environment_encryption_algorithm] @property_value, @operation_id
            IF @ret <> 0
            BEGIN
                RAISERROR (27167, 16, 1, @property_value,@property_value ) WITH NOWAIT
            END
            
            EXEC @ret = [internal].[configure_execution_encryption_algorithm] @property_value, @operation_id
            IF @ret <> 0
            BEGIN
                RAISERROR (27168,16,1, @property_value,@property_value) WITH NOWAIT
            END           
            
            EXEC @ret = [internal].[configure_project_encryption_algorithm] @property_value,@old_algorithm_name, @operation_id
            IF @ret <> 0
            BEGIN
                RAISERROR (27168,16,1, @property_value,@property_value) WITH NOWAIT
            END 
            
            
            UPDATE [internal].[catalog_properties] 
                SET property_value = @property_value
                WHERE property_name = 'ENCRYPTION_ALGORITHM'                    
            
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
            THROW;
        END CATCH      
    END
    
    ELSE IF (UPPER(@property_name) = 'RETENTION_WINDOW')
        BEGIN
            
            BEGIN TRY
                DECLARE @retention_window INT
                SET @retention_window = CONVERT(INT, @property_value)
                
                IF @retention_window <= 0 OR @retention_window >3650
                BEGIN
                    RAISERROR(27101, 16, 14, N'property_value') WITH NOWAIT
                END
                    
                UPDATE [internal].[catalog_properties] 
                    SET property_value = @property_value
                    WHERE property_name = 'RETENTION_WINDOW'

                IF @@ROWCOUNT <> 1
                BEGIN
                    RAISERROR(27112, 16, 8, N'isserver_property') WITH NOWAIT;
                END                             
            END TRY
            BEGIN CATCH
                UPDATE [internal].[operations] SET 
                    [end_time]  = SYSDATETIMEOFFSET(),
                    [status]    = 4
                    WHERE operation_id    = @operation_id;  
                THROW;
            END CATCH
        END
    ELSE IF (UPPER(@property_name) = 'MAX_PROJECT_VERSIONS')
        BEGIN
            
            BEGIN TRY
                DECLARE @version_count INT
                SET @version_count = CONVERT(INT, @property_value)

                IF @version_count <= 0 OR @version_count > 9999
                BEGIN
                    RAISERROR(27101, 16, 16, N'property_value') WITH NOWAIT
                END
                
                UPDATE [internal].[catalog_properties] 
                    SET property_value = @property_value
                    WHERE property_name = 'MAX_PROJECT_VERSIONS'

                IF @@ROWCOUNT <> 1
                BEGIN
                    RAISERROR(27112, 16, 9, N'isserver_property') WITH NOWAIT;
                END       
            END TRY
            
            BEGIN CATCH
                UPDATE [internal].[operations] SET 
                    [end_time]  = SYSDATETIMEOFFSET(),
                    [status]    = 4
                    WHERE operation_id    = @operation_id;
                    THROW;
            END CATCH
        END
           
        ELSE IF (UPPER(@property_name) = 'OPERATION_CLEANUP_ENABLED')
        BEGIN
            
            BEGIN TRY

                IF @property_value NOT IN ('TRUE', 'FALSE')
                BEGIN
                    RAISERROR(27101, 16, 16, N'property_value') WITH NOWAIT
                END
                
                UPDATE [internal].[catalog_properties] 
                    SET property_value = @property_value
                    WHERE property_name = 'OPERATION_CLEANUP_ENABLED'

                IF @@ROWCOUNT <> 1
                BEGIN
                    RAISERROR(27112, 16, 9, N'isserver_property') WITH NOWAIT;
                END       
            END TRY
            
            BEGIN CATCH
                UPDATE [internal].[operations] SET 
                    [end_time]  = SYSDATETIMEOFFSET(),
                    [status]    = 4
                    WHERE operation_id    = @operation_id;
                    THROW;
            END CATCH
        END 

        ELSE IF (UPPER(@property_name) = 'VERSION_CLEANUP_ENABLED')
        BEGIN
            
            BEGIN TRY
            
                IF @property_value NOT IN ('TRUE', 'FALSE')
                BEGIN
                    RAISERROR(27101, 16, 16, N'property_value') WITH NOWAIT
                END
                
                UPDATE [internal].[catalog_properties] 
                    SET property_value = @property_value
                    WHERE property_name = 'VERSION_CLEANUP_ENABLED'

                IF @@ROWCOUNT <> 1
                BEGIN
                    RAISERROR(27112, 16, 9, N'isserver_property') WITH NOWAIT;
                END       
            END TRY
            
            BEGIN CATCH
                UPDATE [internal].[operations] SET 
                    [end_time]  = SYSDATETIMEOFFSET(),
                    [status]    = 4
                    WHERE operation_id    = @operation_id;
                    THROW;
            END CATCH
        END 

        ELSE IF (UPPER(@property_name) = 'SERVER_LOGGING_LEVEL')
        BEGIN
            
            BEGIN TRY
                DECLARE @server_logging_level INT
				DECLARE @server_custom_logging_level_name NVARCHAR(128)
                SET @server_logging_level = CONVERT(INT, @property_value)
                IF ((@server_logging_level < 0 OR @server_logging_level > 4)
					AND @server_logging_level <> 100)
                BEGIN
                    RAISERROR(27217, 16 , 1, @server_logging_level) WITH NOWAIT
                END
				
				
				IF (@server_logging_level = 100)
				BEGIN
				   SELECT @server_custom_logging_level_name = property_value
                   FROM [internal].[catalog_properties] 
                   WHERE property_name = 'SERVER_CUSTOMIZED_LOGGING_LEVEL'
				   
				   IF (@server_custom_logging_level_name is null or @server_custom_logging_level_name = '') 
				   BEGIN
				      RAISERROR(27241, 16 , 1, @server_logging_level) WITH NOWAIT
				   END
				END
                    
                UPDATE [internal].[catalog_properties] 
                    SET property_value = @property_value
                    WHERE property_name = 'SERVER_LOGGING_LEVEL'

                IF @@ROWCOUNT <> 1
                BEGIN
                    RAISERROR(27112, 16, 8, N'isserver_property') WITH NOWAIT;
                END                             
            END TRY
            BEGIN CATCH
                UPDATE [internal].[operations] SET 
                    [end_time]  = SYSDATETIMEOFFSET(),
                    [status]    = 4
                    WHERE operation_id    = @operation_id;  
                THROW;
            END CATCH
        END  

		ELSE IF (UPPER(@property_name) = 'SERVER_CUSTOMIZED_LOGGING_LEVEL')
		BEGIN
			
			BEGIN TRY
				DECLARE @level_name NVARCHAR(128)
				SET @level_name = CONVERT(NVARCHAR(128),@property_value)
				IF NOT EXISTS 
				(
					SELECT [name]
					FROM [internal].[customized_logging_levels]
					WHERE [name] = @level_name
				) AND
				@level_name <> ''
				BEGIN
					RAISERROR(27237, 16, 1, @level_name) WITH NOWAIT
				END
							
				
				
				IF EXISTS 
				(
					SELECT [name]
					FROM [internal].[customized_logging_levels]
					WHERE [name] = @level_name
				)
				BEGIN
				   UPDATE [internal].[catalog_properties] 
                      SET property_value = 100
                      WHERE property_name = 'SERVER_LOGGING_LEVEL'
                END

				UPDATE [internal].[catalog_properties] 
                    SET property_value = @property_value
                    WHERE property_name = 'SERVER_CUSTOMIZED_LOGGING_LEVEL'

                IF @@ROWCOUNT <> 1
                BEGIN
                    RAISERROR(27112, 16, 8, N'isserver_property') WITH NOWAIT;
                END                             
            END TRY
            BEGIN CATCH
                UPDATE [internal].[operations] SET 
                    [end_time]  = SYSDATETIMEOFFSET(),
                    [status]    = 4
                    WHERE operation_id    = @operation_id;  
                THROW;
            END CATCH

        END

        ELSE IF (UPPER(@property_name) = 'SERVER_OPERATION_ENCRYPTION_LEVEL')
        BEGIN
            SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
            SET @tran_count = @@TRANCOUNT;
                    
            IF @tran_count > 0
            BEGIN
                SET @savepoint_name = REPLACE(CONVERT(NCHAR(36), NEWID()), N'-', N'');
                SAVE TRANSACTION @savepoint_name;
            END
            ELSE
                BEGIN TRANSACTION;
            BEGIN TRY
                DECLARE @server_operation_encryption_level int
                DECLARE @curr_level int

                
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
                    RAISERROR(27162, 16 , 1, N'SERVER_OPERATION_ENCRYPTION_LEVEL' ) WITH NOWAIT
                END

                SET @server_operation_encryption_level = CONVERT(int, @property_value)
                IF @server_operation_encryption_level NOT in (1, 2)      
                BEGIN
                    RAISERROR(27101,16,1,'propery_value')
                END

                SELECT @curr_level = CONVERT(int, property_value)
                    FROM [internal].[catalog_properties] WITH (UPDLOCK)
                    WHERE property_name = 'SERVER_OPERATION_ENCRYPTION_LEVEL'

                IF @curr_level NOT in (1, 2)         
                BEGIN
                    RAISERROR(27163    ,16,1,'SERVER_OPERATION_ENCRYPTION_LEVEL')
                END
		  
                IF (@server_operation_encryption_level <> @curr_level) 
                BEGIN
                    IF (EXISTS(SELECT [operation_id]
                        FROM [internal].[operations]
                        WHERE operation_type = 200))
                    BEGIN
                        RAISERROR(27141, 16, 1) WITH NOWAIT;
                    END

                    UPDATE [internal].[catalog_properties] 
                        SET property_value = @property_value
                        WHERE property_name = 'SERVER_OPERATION_ENCRYPTION_LEVEL'

                    IF @@ROWCOUNT <> 1
                    BEGIN
                        RAISERROR(27112, 16, 8, N'isserver_property') WITH NOWAIT;
                    END
                END
                
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
                THROW;
            END CATCH
        END
        ELSE IF (UPPER(@property_name) = 'DEFAULT_EXECUTION_MODE')
        BEGIN
            
            BEGIN TRY

                IF @property_value NOT IN ('0', '1')
                BEGIN
                    RAISERROR(27101, 16, 16, N'property_value') WITH NOWAIT
                END
                
                UPDATE [internal].[catalog_properties] 
                    SET property_value = @property_value
                    WHERE property_name = 'DEFAULT_EXECUTION_MODE'

                IF @@ROWCOUNT <> 1
                BEGIN
                    RAISERROR(27112, 16, 9, N'default exection mode') WITH NOWAIT;
                END       
            END TRY
            
            BEGIN CATCH
                UPDATE [internal].[operations] SET 
                    [end_time]  = SYSDATETIMEOFFSET(),
                    [status]    = 4
                    WHERE operation_id    = @operation_id;
                    THROW;
            END CATCH
        END
    ELSE
        BEGIN
            
            RAISERROR(27101, 16, 13, N'property_name') WITH NOWAIT
            RETURN 1  
        END
    
    UPDATE [internal].[operations] SET 
        [end_time]  = SYSDATETIMEOFFSET(),
        [status]    = 7
        WHERE operation_id    = @operation_id 
    RETURN 0          
END
