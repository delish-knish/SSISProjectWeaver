
CREATE PROCEDURE [internal].[prepare_validate_project] 
        @folder_name                     nvarchar(128),
        @project_name                    nvarchar(128),
        @validate_type                   char(1),             
        @use32bitruntime                 bit =0,            
        @environment_scope              char(1) = 'D',     
        @reference_id                    bigint = NULL,
        @validation_id                   bigint OUTPUT,
        @project_id                      bigint OUTPUT,
        @version_id                      bigint OUTPUT
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

    DECLARE @created_time    DATETIMEOFFSET
    DECLARE @return_value   int
    DECLARE @operation_id bigint
    DECLARE @result bit
    
    BEGIN TRY
        SET @created_time = SYSDATETIMEOFFSET() 
        
        EXEC @return_value = [internal].[insert_operation] 
                        300,  
                        @created_time,          
                        20,    
                        NULL,                   
                        @project_name,          
                        5,    
                        @created_time,          
                        null,                   
                        @caller_sid,            
                        @caller_name,           
                        null,                   
                        null,                   
                        null,                   
                        @operation_id OUTPUT  
        IF @return_value <> 0
            RETURN 1;
        
        SET @validation_id = @operation_id
        
        EXEC @return_value = [internal].[init_object_permissions] 4, @operation_id, @caller_id

                      
        IF @return_value <> 0
        BEGIN
            
            RAISERROR(27153, 16, 1) WITH NOWAIT
            RETURN 1
        END 
    END TRY
    BEGIN CATCH
        UPDATE [internal].[operations] SET 
            [end_time]  = SYSDATETIMEOFFSET(),
            [status]    = 4
            WHERE operation_id    = @operation_id;
        THROW           
    END CATCH

    
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
               
        
        SELECT @project_id = projs.[project_id],  
               @version_id = projs.[object_version_lsn]
            FROM [catalog].[projects] projs INNER JOIN [catalog].[folders] fds
            ON projs.[folder_id] = fds.[folder_id] 
            WHERE fds.[name] = @folder_name AND projs.[name] = @project_name
        
        IF (@project_id IS NULL OR @version_id IS NULL)
        BEGIN
            RAISERROR(27109, 16, 1, @project_name) WITH NOWAIT
        END
        
        INSERT into [internal].[validations]
               (
                  [validation_id],
                  [environment_scope],
                  [validate_type],
                  [folder_name],
                  [project_name],
                  [project_lsn],
                  [use32bitruntime],
                  [reference_id]
               )
        VALUES (
                  @validation_id,              
                  @environment_scope,
                  @validate_type,              
                  @folder_name,               
                  @project_name,              
                  @version_id,                
                  @use32bitruntime,           
                  @reference_id               
               )
        
        UPDATE [internal].[operations]
            SET [object_id] = @project_id
            WHERE [operation_id] = @operation_id
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
        UPDATE [internal].[operations] SET 
            [end_time]  = SYSDATETIMEOFFSET(),
            [status]    = 4
            WHERE operation_id    = @operation_id;
        THROW;
    END CATCH
    RETURN 0
