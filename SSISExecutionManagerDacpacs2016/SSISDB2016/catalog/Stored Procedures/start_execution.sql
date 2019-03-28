CREATE PROCEDURE [catalog].[start_execution]
        @execution_id       bigint   
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
    
    DECLARE @return_value int
    
    IF (@execution_id IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 1) WITH NOWAIT 
        RETURN 1 
    END   

    IF @execution_id <= 0
    BEGIN
        RAISERROR(27101, 16 , 1, N'execution_id') WITH NOWAIT
        RETURN 1;
    END
    
    DECLARE @project_id bigint
    DECLARE @version_id bigint
    DECLARE @use32bitruntime bit
      
    EXEC @return_value = [internal].[prepare_execution] 
        @execution_id,
        @project_id output,
        @version_id output,
        @use32bitruntime output
 
    IF (@return_value <> 0)         
    
    BEGIN
        RETURN 1               
    END  
         
    BEGIN TRY        
        EXEC @return_value = 
                    [internal].[start_execution_internal] 
                            @project_id,
                            @execution_id,
                            @version_id, 
                            @use32bitruntime 
    END TRY
    
    BEGIN CATCH           
        UPDATE [internal].[operations] SET 
            [end_time]  = SYSDATETIMEOFFSET(),
            [status]    = 4
            WHERE operation_id    = @execution_id;
        THROW;
    END CATCH
                             
    
    IF (@return_value <> 0) 
    BEGIN
        UPDATE [internal].[operations] 
           SET [status] = 4,
           [end_time]  = SYSDATETIMEOFFSET()
           WHERE [operation_id] = @execution_id 
        RETURN 1               
    END

    RETURN (@return_value)      
