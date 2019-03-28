CREATE PROCEDURE [internal].[prepare_execution]
        @execution_id       bigint,         
        @project_id         bigint output,  
        @version_id         bigint output,  
        @use32bitruntime    bit output      
AS 
    SET NOCOUNT ON
    DECLARE @result bit
    DECLARE @project_name nvarchar(128)
    DECLARE @folder_name nvarchar(128)

    
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
        
        DECLARE @id bigint
        EXECUTE AS CALLER
            SELECT @id = [operation_id] FROM [catalog].[operations]
                WHERE [operation_id] = @execution_id 
                  AND [object_type] = 20
                  AND [operation_type] = 200
        REVERT    
        
        IF @id IS NULL
        BEGIN
            RAISERROR(27103 , 16 , 1, @execution_id) WITH NOWAIT
        END
        
        
        
        SET @result = [internal].[check_permission] 
            (
                4,
                @execution_id,
                2
            ) 
        
        IF @result = 0
        BEGIN
            RAISERROR(27103 , 16 , 1, @execution_id) WITH NOWAIT        
        END
                   
        
        SELECT @project_id = [object_id],
               @project_name = [project_name],
               @version_id = [project_lsn], 
               @folder_name = [folder_name],
               @use32bitruntime = [use32bitruntime]
            FROM [internal].[execution_info]
            WHERE [execution_id] = @execution_id 
              AND [status] = 1
              AND [object_type] = 20
              AND [operation_type] = 200
        
        IF (@project_id IS NULL)
        BEGIN
            RAISERROR(27121 , 16 , 1) WITH NOWAIT
        END

        

        SELECT @folder_name = fd.[name]
        FROM [catalog].[projects] proj INNER JOIN
            [catalog].[folders] fd ON proj.[folder_id] = fd.[folder_id] WHERE
            fd.[name] = @folder_name AND proj.[project_id] = @project_id
        
        IF @folder_name IS NULL
        BEGIN
            RAISERROR(27109 , 16 , 1, @project_name) WITH NOWAIT        
        END

        
        SET @result = [internal].[check_permission] 
            (
                2,
                @project_id,
                3
            ) 

        
        IF @result = 0
        BEGIN
            RAISERROR(27178 , 16 , 1, @project_name) WITH NOWAIT        
        END
        
        
        DECLARE @version_current bigint
        SET @version_current = (SELECT [object_version_lsn] 
                                    FROM [internal].[projects]
                                    WHERE [project_id] = @project_id)
        
        IF (@version_current <> @version_id)
        BEGIN
            RAISERROR(27150 , 16 , 1) WITH NOWAIT
        END
        
        
        IF EXISTS (SELECT [execution_parameter_id] 
            FROM [internal].[execution_parameter_values]
            WHERE [execution_id] = @execution_id AND [required] = 1 AND [value_set] = 0)
        BEGIN
            RAISERROR(27184 , 16 , 1) WITH NOWAIT 
        END
        
        
        EXEC [internal].[set_system_informations]
              @execution_id

        
        UPDATE [internal].[operations]
        SET [status] = 5,
            [start_time] = SYSDATETIMEOFFSET(),
            [server_name] = CONVERT(sysname, SERVERPROPERTY('servername')),
            [machine_name] = CONVERT(sysname, SERVERPROPERTY('machinename'))
        WHERE [operation_id] = @execution_id
        IF @@ROWCOUNT <> 1
        BEGIN
            RAISERROR(27112, 16, 1, N'operations') WITH NOWAIT
        END       
            
        
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        THROW;
    END CATCH
    
    RETURN 0
