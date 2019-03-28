
CREATE PROCEDURE [catalog].[start_execution]
        @execution_id       	bigint,   
		@retry_count			int = 0	 
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
	
	IF @retry_count < 0
	BEGIN
		RAISERROR(27101, 16, 1, N'retry_count') WITH NOWAIT
		RETURN 1
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
    
	
	IF (0 = 0 AND EXISTS (SELECT 1 FROM [internal].[executions] WHERE [execution_id]=@execution_id AND [job_id] IS NULL))
	BEGIN
		BEGIN TRY        
            UPDATE [internal].[operations] 
            SET [executed_count] = 1
            WHERE operation_id = @execution_id;

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
    END
	
	
	ELSE
	BEGIN
		BEGIN TRY
			EXEC @return_value = 
					[internal].[create_execution_job]
						@execution_id,
						@caller_name,
						@retry_count
		END TRY
		
		BEGIN CATCH           
			UPDATE [internal].[operations] SET 
				[end_time]  = SYSDATETIMEOFFSET(),
				[status]    = 4
				WHERE operation_id    = @execution_id;
			THROW;
		END CATCH
		
		IF EXISTS(SELECT * FROM [internal].[execution_parameter_values] WHERE execution_id = @execution_id AND parameter_name = 'SYNCHRONIZED' AND parameter_value = 1 AND object_type = 50)
		BEGIN
			DECLARE @status int = NULL
			WHILE @status IS NULL
			BEGIN        WAITFOR DELAY '00:00:02'  
				
				SELECT @status = [status] FROM [catalog].[operations] 
				WHERE operation_id = @execution_id AND [status] <> 5 AND [status] <> 2
			END
		END
	END
	
    
    IF (@return_value <> 0) 
    BEGIN
        UPDATE [internal].[operations] 
           SET [status] = 4,
           [end_time]  = SYSDATETIMEOFFSET()
           WHERE [operation_id] = @execution_id 
        RETURN 1               
    END

    RETURN (@return_value)      
