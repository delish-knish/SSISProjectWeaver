CREATE PROCEDURE [internal].[append_packages]
        @project_id             bigint,
        @object_version_lsn     bigint,
        @packages_data         [internal].[PackageTableType] READONLY
AS
    SET NOCOUNT ON
    
    DECLARE @result bit

    IF (@project_id IS NULL  OR @object_version_lsn IS NULL )
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
   
    
    INSERT INTO [internal].[packages]
           ([project_version_lsn]
           ,[name]
           ,[package_guid]
           ,[description]
           ,[package_format_version]
           ,[version_major]
           ,[version_minor]
           ,[version_build]
           ,[version_comments]
           ,[version_guid]
           ,[project_id]
           ,[entry_point]
           ,[validation_status]
           ,[last_validation_time]
           ,[package_data])
        SELECT            
            @object_version_lsn
           ,[name]
           ,[package_guid]
           ,[description]
           ,[package_format_version]
           ,[version_major]
           ,[version_minor]
           ,[version_build]
           ,[version_comments]
           ,[version_guid]
           ,@project_id
           ,[entry_point]
           ,[validation_status]
           ,[last_validation_time]
           ,[package_data] 
        FROM @packages_data      
      
      RETURN 0     
