CREATE PROCEDURE [catalog].[get_parameter_values]
    @folder_name nvarchar(128),
    @project_name nvarchar(128),
    @package_name nvarchar(260),
    @reference_id  bigint = NULL
AS
    SET NOCOUNT ON
    DECLARE @project_id bigint
    DECLARE @environment_id bigint
    DECLARE @version_id bigint
    DECLARE @result bit
    DECLARE @environment_found bit
    
    IF (@folder_name IS NULL OR @project_name IS NULL 
            OR @package_name IS NULL )
    BEGIN
        RAISERROR(27138, 16 , 1) WITH NOWAIT 
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
    
        EXECUTE AS CALLER
            SELECT @project_id = projs.[project_id],
                   @version_id = projs.[object_version_lsn]
                FROM [catalog].[projects] projs INNER JOIN [catalog].[folders] fds
                ON projs.[folder_id] = fds.[folder_id] INNER JOIN [catalog].[packages] pkgs
                ON projs.[project_id] = pkgs.[project_id] 
                WHERE fds.[name] = @folder_name AND projs.[name] = @project_name
                AND pkgs.[name] = @package_name
        REVERT
        
        IF (@project_id IS NULL)
        BEGIN
            RAISERROR(27146, 16, 1) WITH NOWAIT
        END
        
        DECLARE @environment_name nvarchar(128)
        DECLARE @environment_folder_name nvarchar(128)
        DECLARE @reference_type char(1)
        
        
        DECLARE @result_set TABLE
        (
            [parameter_id] bigint,
            [object_type] smallint, 
            [parameter_data_type] nvarchar(128),
            [parameter_name] nvarchar(128),
            [parameter_value] sql_variant,
            [sensitive]  bit,
            [required]  bit,
            [value_set] bit
        );
        
        
        IF(@reference_id IS NOT NULL)
        BEGIN
            
            EXECUTE AS CALLER
                SELECT @environment_name = environment_name,
                       @environment_folder_name = environment_folder_name,
                       @reference_type = reference_type
                FROM [catalog].[environment_references]
                WHERE project_id = @project_id AND reference_id = @reference_id
            REVERT
            IF (@environment_name IS NULL)
            BEGIN
                RAISERROR(27208, 16, 1, @reference_id) WITH NOWAIT
            END                                                     
            
            
            SET @environment_found = 1
            IF (@reference_type = 'A')
            BEGIN
                SELECT @environment_id = envs.[environment_id]
                FROM [internal].[folders] fds INNER JOIN [internal].[environments] envs
                ON fds.[folder_id] = envs.[folder_id]
                WHERE envs.[environment_name] = @environment_name AND fds.[name] = @environment_folder_name
            END
            ELSE IF (@reference_type = 'R')
            BEGIN
                SELECT @environment_id = envs.[environment_id]
                FROM  [internal].[projects] projs INNER JOIN [internal].[environments] envs
                ON projs.[folder_id] = envs.[folder_id]
                WHERE envs.[environment_name] = @environment_name AND projs.[project_id] = @project_id
            END
            IF (@environment_id IS NULL)
            BEGIN
                SET @environment_found = 0
            END
            
            EXECUTE AS CALLER
                SET @result =  [internal].[check_permission]
                    (
                        3,
                        @environment_id,
                        1
                     )
            REVERT
            IF @result = 0
            BEGIN
                SET @environment_found = 0
            END
            
            IF @environment_found = 0
            BEGIN
                RAISERROR(27182 , 16 , 1, @environment_name) WITH NOWAIT
            END
            
            
            INSERT INTO @result_set 
            SELECT params.[parameter_id],
                   params.[object_type],  
                   params.[data_type],
                   params.[parameter_name],
                   NULL,
                   params.[sensitive],
                   params.[required],
                   params.[value_set]
            FROM [catalog].[object_parameters] params INNER JOIN
             ([internal].[environments] envs INNER JOIN [internal].[environment_variables] vars
            ON envs.[environment_id] = vars.[environment_id])
            ON vars.[name] = params.[referenced_variable_name] AND params.[value_type] = 'R'
            WHERE  params.[project_id] = @project_id
            AND (params.[object_type] = 20
            OR (params.[object_name] = @package_name
            AND params.[object_type] = 30))
            AND envs.[environment_id] = @environment_id
            AND params.[data_type] <> vars.[type]
                       
            
            DECLARE @pname  nvarchar(128)
            DECLARE @otype  smallint
            
            DECLARE result_cursor CURSOR LOCAL FOR
            SELECT [parameter_name], [object_type]
            FROM @result_set
            
            OPEN result_cursor
            FETCH NEXT FROM result_cursor
            INTO @pname, @otype
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                RAISERROR(27148, 10, 1, @pname) WITH NOWAIT
                FETCH NEXT FROM result_cursor
                INTO @pname, @otype
            END
            CLOSE result_cursor
            DEALLOCATE result_cursor
                 
        END
    
        INSERT INTO @result_set 
        SELECT [parameter_id],
               [object_type],  
               [parameter_data_type],
               [parameter_name],
               [default_value],
               [sensitive],
               [required],
               [value_set] 
        FROM [internal].[object_parameters] 
        WHERE [project_id] = @project_id 
        AND ([object_type] = 20 
        OR ([object_name] = @package_name 
        AND [object_type] = 30))
        AND [value_type] = 'V' 
        AND [project_version_lsn] = @version_id       

        
        IF @environment_id IS NOT NULL
        BEGIN
            INSERT INTO @result_set 
            SELECT params.[parameter_id],
                   params.[object_type],  
                   params.[parameter_data_type],
                   params.[parameter_name],
                   vars.[value],
                   params.[sensitive],
                   params.[required],
                   params.[value_set]
            FROM [internal].[object_parameters] params 
            INNER JOIN [internal].[environment_variables] vars
                ON params.[referenced_variable_name] = vars.[name] 
            WHERE params.[project_id] = @project_id 
            AND (params.[object_type] = 20
            OR (params.[object_name] = @package_name 
            AND params.[object_type] = 30))
            AND params.[value_type] = 'R' 
            AND params.[parameter_data_type] = vars.[type]
            AND params.[project_version_lsn] = @version_id
            AND vars.[environment_id] = @environment_id
        END

        
        INSERT INTO @result_set 
        SELECT objParams.[parameter_id],
               objParams.[object_type],  
               objParams.[parameter_data_type],
               objParams.[parameter_name],
               NULL,
               objParams.[sensitive],
               objParams.[required],
               objParams.[value_set]
        FROM [internal].[object_parameters] objParams LEFT JOIN @result_set resultset
        ON objParams.[object_type] = resultset.[object_type]
        AND objParams.[parameter_name] = resultset.[parameter_name] COLLATE SQL_Latin1_General_CP1_CS_AS
        WHERE objParams.[project_id] = @project_id 
        AND objParams.[object_name] = @package_name 
        AND objParams.[object_type] = 30
        AND objParams.[value_type] = 'R' 
        AND objParams.[project_version_lsn] = @version_id 
        AND resultset.[parameter_name] IS NULL
            
        INSERT INTO @result_set 
        SELECT objParams.[parameter_id],
               objParams.[object_type],  
               objParams.[parameter_data_type],
               objParams.[parameter_name],
               NULL,
               objParams.[sensitive],
               objParams.[required],
               objParams.[value_set]
        FROM [internal].[object_parameters] objParams LEFT JOIN @result_set resultset
        ON objParams.[object_type] = resultset.[object_type]
        AND objParams.[parameter_name] = resultset.[parameter_name] COLLATE SQL_Latin1_General_CP1_CS_AS
        WHERE objParams.[project_id] = @project_id 
        AND objParams.[object_name] = @project_name 
        AND objParams.[object_type] = 20
        AND objParams.[value_type] = 'R' 
        AND objParams.[project_version_lsn] = @version_id 
        AND resultset.[parameter_name] IS NULL
        
        SELECT [parameter_id] ,
            [object_type], 
            [parameter_data_type],
            [parameter_name],
            [parameter_value],
            [sensitive],
            [required],
            [value_set]
        FROM @result_set
        
    
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        
        IF (CURSOR_STATUS('local', 'result_cursor') = 1 
            OR CURSOR_STATUS('local', 'result_cursor') = 0)
        BEGIN
            CLOSE result_cursor
            DEALLOCATE result_cursor            
        END;             
        THROW;
    END CATCH
    
    RETURN 0      
    
