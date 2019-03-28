CREATE PROCEDURE [catalog].[check_schema_version]
		@use32bitruntime		smallint			
AS
	SET NOCOUNT ON

	
	IF (@use32bitruntime IS NULL)
	BEGIN
        RAISERROR(27138, 16 , 4) WITH NOWAIT
        RETURN 1
    END

    
    
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

    DECLARE @created_time  DATETIMEOFFSET
    DECLARE @return_value  int
    DECLARE @operation_id  bigint
    DECLARE @result        bit

	BEGIN TRY
        SET @created_time = SYSDATETIMEOFFSET() 
        
        EXEC @return_value = [internal].[insert_operation] 
                        700,  
                        @created_time,          
                        NULL,                   
                        NULL,                   
                        NULL,                   
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
            WHERE operation_id = @operation_id;
        THROW           
    END CATCH

	if (@operation_id IS NULL)
	BEGIN
		
		RETURN 1
	END

	BEGIN TRY	
		DECLARE	@serverBuild nvarchar(1024),
				@schemaVersion int,
				@schemaBuild nvarchar(1024),
				@assemblyBuild nvarchar(1024),
				@componentVersion nvarchar(1024),
				@compatibilityStatus smallint

		EXEC	@return_value = [internal].[check_schema_version_internal]
									@operationId = @operation_id,
									@use32bitruntime = @use32bitruntime,
									@serverBuild = @serverBuild OUTPUT,
									@schemaVersion = @schemaVersion OUTPUT,
									@schemaBuild = @schemaBuild OUTPUT,
									@assemblyBuild = @assemblyBuild OUTPUT,
									@componentVersion = @componentVersion OUTPUT,
									@compatibilityStatus = @compatibilityStatus OUTPUT
		
		
		if @return_value <> 0
			RETURN 1

		
        UPDATE [internal].[operations] SET 
            [end_time]  = SYSDATETIMEOFFSET(),
            [status]    = 7
            WHERE operation_id    = @operation_id; 

		
        SELECT  @serverBuild as N'SERVER_BUILD',
				@schemaVersion as N'SCHEMA_VERSION',
				@schemaBuild as N'SCHEMA_BUILD',
				@assemblyBuild as N'ASSEMBLY_BUILD',
				@componentVersion as N'SHARED_COMPONENT_VERSION',
				@compatibilityStatus as N'COMPATIBILITY_STATUS'
	END TRY
	BEGIN CATCH
		
	    UPDATE [internal].[operations] 
        SET [status] = 4,
            [end_time]  = SYSDATETIMEOFFSET()
        WHERE [operation_id] = @operation_id;
		THROW
	END CATCH

	RETURN 0
