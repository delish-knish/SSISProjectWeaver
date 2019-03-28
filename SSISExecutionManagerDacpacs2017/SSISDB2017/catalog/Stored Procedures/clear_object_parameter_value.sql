
CREATE PROCEDURE [catalog].[clear_object_parameter_value]
        @folder_name            nvarchar(128),
        @project_name           nvarchar(128),
        @object_type            smallint,
        @object_name            nvarchar(260) = NULL,
        @parameter_name         nvarchar(128)
AS
    SET NOCOUNT ON
     
    DECLARE @result bit
    DECLARE @parameter_id bigint
    
    
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
            OR @parameter_name IS NULL )
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1     
    END   
    
    IF @object_type NOT IN (20, 30)
    BEGIN
        RAISERROR(27101, 16 , 1, N'object_type') WITH NOWAIT
        RETURN 1;
    END
    
    IF (@object_type = 30 AND @object_name IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
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
        
        IF @object_type = 20  
        BEGIN
            SELECT @parameter_id = [parameter_id]
                FROM [catalog].[object_parameters]
                WHERE [project_id] = @project_id AND [object_type] = @object_type
                AND [parameter_name] = @parameter_name COLLATE SQL_Latin1_General_CP1_CS_AS
        END
        ELSE IF @object_type = 30  
        BEGIN
            SELECT @parameter_id = [parameter_id]
                FROM [catalog].[object_parameters]
                WHERE [project_id] = @project_id AND [object_type] = @object_type
                AND [parameter_name] = @parameter_name COLLATE SQL_Latin1_General_CP1_CS_AS
                AND [object_name] = @object_name
        END
        
        IF @parameter_id IS NULL
        BEGIN
            RAISERROR( 27106 , 16 , 1, @parameter_name) WITH NOWAIT     
        END        

        UPDATE [internal].[object_parameters]
            SET [default_value] = NULL,
                [sensitive_default_value] = NULL,
                [base_data_type] = NULL,
                [value_type] = 'V',
                [value_set] = 0,
                [referenced_variable_name] = NULL
        WHERE parameter_id = @parameter_id
        IF @@ROWCOUNT <> 1
        BEGIN
            RAISERROR(27112, 16, 1, N'object_parameters') WITH NOWAIT
        END       
                  
        
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
