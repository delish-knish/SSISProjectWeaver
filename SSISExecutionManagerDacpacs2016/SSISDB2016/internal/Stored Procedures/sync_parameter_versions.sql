CREATE PROCEDURE [internal].[sync_parameter_versions]
        @project_id             bigint,
        @object_version_lsn     bigint
AS
    SET NOCOUNT ON
    
    DECLARE @result bit

    IF (@project_id IS NULL  OR @object_version_lsn IS NULL)
    BEGIN
        RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1     
    END
    
    IF (@project_id <= 0)
    BEGIN
        RAISERROR(27101, 16 , 10, N'project_id') WITH NOWAIT
        RETURN 1 
    END

    IF (@object_version_lsn <= 0)
    BEGIN
        RAISERROR(27101, 16 , 10, N'object_version_lsn') WITH NOWAIT
        RETURN 1  
    END  
    
    IF NOT EXISTS (SELECT [object_version_lsn] FROM [internal].[object_versions] 
                WHERE [object_version_lsn] = @object_version_lsn AND [object_type] = 20
                AND [object_id] = @project_id AND [object_status] = 'D')
    BEGIN
        RAISERROR(27194 , 16 , 1) WITH NOWAIT
        RETURN 1         
    END

    SET @result = [internal].[check_permission] 
    (
        2,
        @project_id,
        2
    ) 

    IF @result = 0        
    BEGIN
        RAISERROR(27194 , 16 , 1) WITH NOWAIT
        RETURN 1        
    END
    DECLARE @latest_version bigint
    
    SELECT @latest_version = object_version_lsn 
        FROM [catalog].[projects] WHERE [project_id] = @project_id
    
    IF (@latest_version IS NOT NULL)
    BEGIN
        
        WITH ExistingValue( [object_type], [object_name], [parameter_name],
            [parameter_data_type], [required], [sensitive], [default_value], [sensitive_default_value],
            [value_type], [value_set], [referenced_variable_name])
        AS 
           (SELECT [object_type],
                   [object_name],
                   [parameter_name],
                   [parameter_data_type],
                   [required],
                   [sensitive],
                   [default_value],
                   [sensitive_default_value],
                   [value_type],
                   [value_set],
                   [referenced_variable_name]
            FROM [internal].[object_parameters]
            WHERE  [project_id] = @project_id AND [project_version_lsn] = @latest_version)
        UPDATE [internal].[object_parameters]
            SET [default_value] = e.[default_value],
                [sensitive_default_value] = e.[sensitive_default_value],
                [value_type] = e.[value_type],
                [value_set] = e.[value_set],
                [referenced_variable_name] = e.[referenced_variable_name]
            FROM [internal].[object_parameters] AS params
            INNER JOIN ExistingValue e ON
            e.[parameter_data_type] = params.[parameter_data_type] 
            AND e.[parameter_name] = params.[parameter_name] COLLATE SQL_Latin1_General_CP1_CS_AS
            AND e.[sensitive] = params.[sensitive] AND e.[object_type] = params.[object_type]
            AND e.[object_name] = params.[object_name] AND e.[required] = params.[required]
            WHERE params.[project_id] = @project_id AND params.[project_version_lsn] = @object_version_lsn
    END
