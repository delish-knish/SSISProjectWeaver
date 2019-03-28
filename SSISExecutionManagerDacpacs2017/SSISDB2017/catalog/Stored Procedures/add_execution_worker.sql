
CREATE PROCEDURE [catalog].[add_execution_worker]
        @execution_id       bigint,   
		@workeragent_id		uniqueIdentifier 
		
WITH EXECUTE AS 'AllSchemaOwner'
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
	
	DECLARE @result int
	EXECUTE AS CALLER   
		SET @result = [internal].[check_permission] 
			(
				4,
				@execution_id,
				2
			) 
	REVERT
	
	IF @result = 0
	BEGIN
		RAISERROR(27103 , 16 , 1, @execution_id) WITH NOWAIT    
		RETURN 1
	END  
    
    IF (@execution_id IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 1) WITH NOWAIT 
        RETURN 1 
    END   

    IF @execution_id <= 0
    BEGIN
        RAISERROR(27101, 16 , 1, N'execution_id') WITH NOWAIT
        RETURN 1
    END
	
	DECLARE @return_value 		int
	DECLARE @job_id 			uniqueIdentifier = NULL
	
	SELECT @job_id = [job_id] FROM [internal].[executions] WHERE [execution_id]=@execution_id
	
	
	IF @@ROWCOUNT = 0
	BEGIN
		RAISERROR(27103, 16, 1, @execution_id) WITH NOWAIT
		RETURN 1
	END
	ELSE IF @job_id IS NULL
	BEGIN
		RAISERROR(27255, 16, 1) WITH NOWAIT
		RETURN 1
	END	
      
    EXEC @return_value = [internal].[append_job_worker_agent] 
		@job_id,
        @workeragent_id
 
    IF (@return_value <> 0)         
    
    BEGIN
        RETURN 1               
    END     

	RETURN 0
