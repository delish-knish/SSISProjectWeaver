CREATE PROCEDURE [catalog].[deploy_project]
    @folder_name nvarchar(128),
    @project_name nvarchar(128),
    @project_stream varbinary(MAX),
    @operation_id bigint = NULL output
AS
    SET NOCOUNT ON
    
    DECLARE @deploy_id  bigint
    DECLARE @version_id bigint
    DECLARE @project_id bigint
    DECLARE @retval int
    DECLARE @time   datetimeoffset
    DECLARE @status int
              
    IF (@folder_name IS NULL OR @project_name IS NULL OR @project_stream IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1 
    END
    
    IF [internal].[is_valid_name](@project_name) = 0
    BEGIN
        RAISERROR(27145, 16, 1, @project_name) WITH NOWAIT
        RETURN 1
    END
    
     EXEC @retval = [internal].[create_deploy_operation] 
                       @folder_name,
                       @project_name,
                       @deploy_id output
    IF @retval <> 0
    BEGIN
        RETURN 1
    END   
    
    SET @operation_id = @deploy_id
    
    
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
        EXEC @retval = [internal].[prepare_deploy] 
                           @folder_name,
                           @project_name,
                           @project_stream,
                           @deploy_id,
                           @version_id output,
                           @project_id output
        IF @retval <> 0
        BEGIN
            RAISERROR(27118, 16, 1) WITH NOWAIT
        END
    
        EXEC @retval = [internal].[deploy_project_internal]
                            @deploy_id,
                            @version_id,
                            @project_id,
                            @project_name
        IF @retval <> 0
        BEGIN
            RAISERROR(27118,16,1) WITH NOWAIT
        END      
    
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        SET @time = SYSDATETIMEOFFSET()
        
        UPDATE [internal].[operations] SET 
            [end_time]  = SYSDATETIMEOFFSET(),
            [status]    = 4
            WHERE operation_id    = @operation_id;         
        THROW 
    END CATCH
    
    
    DECLARE @process_id bigint
    SELECT @process_id = [process_id] FROM [catalog].[operations] 
        WHERE operation_id = @deploy_id
    
    SET @status = NULL
    WHILE @status IS NULL
    BEGIN
        WAITFOR DELAY '00:00:01'  
        
        SELECT @status = [status] FROM [catalog].[operations] 
                    WHERE operation_id = @deploy_id AND [status] <> 2
                    
        IF @status IS NULL
        BEGIN
           
           IF NOT EXISTS (SELECT [process_id] 
                 FROM internal.get_isserver_processes() 
                 WHERE [process_id]= @process_id)
           BEGIN
               
               
               DECLARE @end_time datetimeoffset(7)
               
               SET @status = 4
               SET @end_time = SYSDATETIMEOFFSET()
               EXEC @retval = [internal].[update_project_deployment_status]
                      @deploy_id,
                      @version_id,
                      @end_time,
                      4,
                      ''  
           END
            
        END
    END
    
    IF @status = 7
    BEGIN
        RETURN 0
    END
    ELSE
    BEGIN
        RAISERROR (27203, 16,1, @deploy_id) WITH NOWAIT
        RETURN 1
    END
