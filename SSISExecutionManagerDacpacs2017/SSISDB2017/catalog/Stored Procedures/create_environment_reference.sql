
CREATE PROCEDURE [catalog].[create_environment_reference]
        @folder_name        nvarchar(128),                  
        @project_name       nvarchar(128),                  
        @environment_name   nvarchar(128),                  
        @reference_type    char(1),                     
        @environment_folder_name nvarchar(128) = null,      
        @reference_id       bigint output                   
AS
    SET NOCOUNT ON
    
    DECLARE @folder_id bigint
    DECLARE @environment_id bigint
    DECLARE @result bit
    
    
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
    
    IF (@folder_name IS NULL OR @project_name IS NULL 
            OR @environment_name IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1 
    END
    
    IF ( @reference_type NOT IN ('R','A'))
    BEGIN
        RAISERROR(27101, 16 , 10, N'reference_type') WITH NOWAIT
        RETURN 1 
    END
        
    
    IF (@reference_type = 'A' AND @environment_folder_name IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1 
    END    
    
    
    IF (@reference_type = 'R' AND @environment_folder_name IS NOT NULL)
    BEGIN
        RAISERROR(27101, 16 , 10, N'environment_folder_name') WITH NOWAIT 
        RETURN 1 
    END    
    
    
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
    
    
    DECLARE @project_id bigint;
    EXECUTE AS CALLER
        SET @project_id = (SELECT projs.[project_id]
                                FROM [catalog].[projects] projs INNER JOIN [catalog].[folders] fld
                                ON projs.[folder_id] = fld.[folder_id]
                                AND projs.[name] = @project_name
                                AND fld.name = @folder_name);
    REVERT
    IF @project_id IS NULL
    BEGIN
        RAISERROR(27109 , 16 , 1, @project_name) WITH NOWAIT
    END
    EXECUTE AS CALLER
        SET @result = [internal].[check_permission]
        (
            2,
            @project_id,
            2
         )
    REVERT
    IF @result = 0
    BEGIN
        RAISERROR(27109 , 16 , 1, @project_name) WITH NOWAIT
    END
    
    
    EXECUTE AS CALLER
    DECLARE @temp_folder_name nvarchar(128)
    IF (@reference_type = 'A')
    BEGIN
      SET @temp_folder_name = @environment_folder_name
    END
    ELSE IF (@reference_type = 'R')
    BEGIN
        SET @temp_folder_name = @folder_name
    END
     SELECT @environment_id = env.[environment_id]
                        FROM [catalog].[environments] env INNER JOIN [catalog].[folders] fld
                        ON env.[folder_id] = fld.[folder_id]
                        WHERE env.[name] = @environment_name
                        AND fld.name = @temp_folder_name
    REVERT
    IF @environment_id IS NULL
    BEGIN
        RAISERROR(27182 , 16 , 1, @environment_name) WITH NOWAIT
    END
    
    SET @result = [internal].[check_permission]
    (
        3,
        @environment_id,
        1
     ) 
    
    IF @result = 0
    BEGIN
        RAISERROR(27182 , 16 , 1, @environment_name) WITH NOWAIT    
    END
    
    DECLARE @insert_folder_value nvarchar(128)
    IF (@reference_type = 'R') 
    BEGIN   
        SET @insert_folder_value = null  
        IF EXISTS (SELECT @reference_id FROM [internal].[environment_references]
            WHERE [reference_type] = @reference_type AND [project_id] = @project_id 
            AND [environment_name] = @environment_name)
        BEGIN
            RAISERROR(27204 , 16 , 1) WITH NOWAIT
        END
    END
    
    ELSE IF (@reference_type = 'A') 
    BEGIN    
        SET @insert_folder_value = @environment_folder_name
        IF EXISTS (SELECT @reference_id FROM [internal].[environment_references]
            WHERE [reference_type] = @reference_type AND [project_id] = @project_id
            AND [environment_name] = @environment_name
            AND [environment_folder_name] = @insert_folder_value)
        BEGIN
            RAISERROR(27204 , 16 , 1) WITH NOWAIT
        END
    END      

    INSERT INTO [internal].[environment_references]
        (project_id, reference_type, environment_folder_name, environment_name, validation_status, last_validation_time) 
         VALUES (@project_id, @reference_type, @insert_folder_value, @environment_name, 'N', null)
    SET @reference_id = SCOPE_IDENTITY()
    
    
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                                  
        THROW 
    END CATCH

    RETURN 0 
