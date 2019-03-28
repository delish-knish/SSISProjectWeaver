 
CREATE PROCEDURE [internal].[cleanup_server_project_version]
AS
    SET NOCOUNT ON
    
    DECLARE @enable_clean_version bit
    DECLARE @max_version_count int
    
    DECLARE @caller_name nvarchar(256)
    DECLARE @caller_sid  varbinary(85)
    DECLARE @operation_id bigint
    
    SET @caller_name =  SUSER_NAME()
    SET @caller_sid =   SUSER_SID()
         
    
    
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
        SELECT @enable_clean_version = CONVERT(bit, property_value) 
            FROM [catalog].[catalog_properties]
            WHERE property_name = 'VERSION_CLEANUP_ENABLED'
        
        IF @enable_clean_version = 1
        BEGIN
            SELECT @max_version_count = CONVERT(int,property_value)  
                FROM [catalog].[catalog_properties]
                WHERE property_name = 'MAX_PROJECT_VERSIONS'
                
            IF @max_version_count <= 0 OR @max_version_count > 9999 
            BEGIN
                RAISERROR(27163    ,16,1,'MAX_PROJECT_VERSIONS')
            END
            
            INSERT INTO [internal].[operations] (
                [operation_type],  
                [created_time], 
                [object_type],
                [object_id],
                [object_name],
                [status], 
                [start_time],
                [caller_sid], 
                [caller_name]
                )
            VALUES (
                2,
                SYSDATETIMEOFFSET(),
                NULL,                     
                NULL,                     
                NULL,                     
                1,      
                SYSDATETIMEOFFSET(),
                @caller_sid,            
                @caller_name            
                ) 
            set @operation_id = SCOPE_IDENTITY();
            
            
            WITH active_projects (object_version_lsn, [object_id], last_active_date)
            AS
            (
            
            SELECT [object_version_lsn], 
                   [object_id], 
                   [last_restored_time] AS [last_active_date] 
            FROM   [internal].[object_versions]
            WHERE  [object_type] = 20 
                AND [last_restored_time] IS NOT NULL
                AND [object_status] = 'C'
            UNION
            
            SELECT [object_version_lsn], 
                   [object_id], 
                   [created_time] AS [last_active_date] 
            FROM   [internal].[object_versions]
            WHERE  [object_type] = 20
                AND [last_restored_time] IS NULL
                AND [object_status] = 'C'
            )

            DELETE FROM [internal].[object_versions] 
            WHERE [object_version_lsn] IN 
                (SELECT [object_version_lsn] FROM
                    (SELECT [object_version_lsn],
                         DENSE_RANK() OVER 
                         (PARTITION BY [object_id] ORDER BY [last_active_date] DESC) AS [project_rank]
                     FROM active_projects
                    ) RankedActiveProjects
                 WHERE RankedActiveProjects.[project_rank] > @max_version_count)
            
            UPDATE [internal].[operations]
                SET [status] = 7,
                [end_time] = SYSDATETIMEOFFSET()
                WHERE [operation_id] = @operation_id                             
        END
        
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        UPDATE [internal].[operations]
            SET [status] = 4,
            [end_time] = SYSDATETIMEOFFSET()
            WHERE [operation_id] = @operation_id;       
        THROW
    END CATCH
    
    RETURN 0
