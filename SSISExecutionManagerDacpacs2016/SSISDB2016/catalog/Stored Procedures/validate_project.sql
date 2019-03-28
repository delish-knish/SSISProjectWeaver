CREATE PROCEDURE [catalog].[validate_project]
        @folder_name                     nvarchar(128),     
        @project_name                    nvarchar(128),     
        @validate_type                   char(1) = 'F',     
        @validation_id                   bigint output,     
        @use32bitruntime                 bit = 0,           
        @environment_scope              char(1) = 'D',     
        @reference_id                    bigint = NULL      
AS 
    SET NOCOUNT ON
    DECLARE @return_value   int
    
    
    IF(@folder_name IS NULL OR @project_name IS NULL 
        OR @validate_type IS NULL OR @environment_scope IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 4) WITH NOWAIT
        RETURN 1
    END
    
    
    IF @validate_type <> 'F'
    BEGIN
        RAISERROR(27101, 16 , 2, N'validate_type') WITH NOWAIT
        RETURN 1;
    END
    
    IF @environment_scope NOT IN ('A','S','D')
    BEGIN
        RAISERROR(27101, 16 , 2, N'environment_scope') WITH NOWAIT
        RETURN 1;
    END  
    
    IF (@validate_type = 'D' AND (@reference_id IS NOT NULL
        OR @environment_scope != 'D')) 
    BEGIN
        RAISERROR(27101, 16 , 2, N'reference_id, environment_scope') WITH NOWAIT
        RETURN 1
    END
    
    IF @environment_scope = 'S' AND @reference_id IS NULL
    BEGIN
        RAISERROR(27101, 16 , 2, N'reference_id') WITH NOWAIT
        RETURN 1;
    END
    
    IF (@environment_scope = 'A' OR @environment_scope = 'D')  AND @reference_id IS NOT NULL
    BEGIN
        RAISERROR(27101, 16 , 2, N'reference_id') WITH NOWAIT
        RETURN 1;
    END 
DECLARE @project_id bigint
    DECLARE @version_id bigint        
    EXEC @return_value =  [internal].[prepare_validate_project] 
                            @folder_name,
                            @project_name,
                            @validate_type,                  
                            @use32bitruntime,
                            @environment_scope,
                            @reference_id,
                            @validation_id OUTPUT,
                            @project_id OUTPUT,
                            @version_id OUTPUT    
    IF (@return_value <> 0)
    
    BEGIN
        RETURN 1  
    END
    
    IF @validation_id IS NULL OR @project_id IS NULL OR @version_id IS NULL
    BEGIN
        
        RETURN 1
    END
    
      
    BEGIN TRY       
        EXEC @return_value = [internal].[validate_project_internal] 
                            @project_id,
                            @version_id,
                            @validation_id,
                            @environment_scope,
                            @use32bitruntime
    END TRY
    BEGIN CATCH
        UPDATE [internal].[operations] 
            SET [status] = 4,
                [end_time]  = SYSDATETIMEOFFSET()
            WHERE [operation_id] = @validation_id;             
        THROW;
    END CATCH       
                
