CREATE PROCEDURE internal.insert_project
        @folder_id              bigint,
        @name                   nvarchar(128),
        @description            nvarchar(1024),
        @project_format_version int,
        @deployed_by_sid          [internal].[adt_sid],
        @deployed_by_name         [internal].[adt_sname],
        @last_deployed_time       datetimeoffset,
        @created_time           datetimeoffset,
        @object_version_lsn     bigint,
        @validation_status      char(1),
        @last_validation_time   datetimeoffset,  
        @project_id             bigint output
WITH EXECUTE AS CALLER
AS
    SET NOCOUNT ON
    
    MERGE [internal].[projects] AS target
    USING( select @folder_id,@name) AS source(folder_id, name)
    ON (target.folder_id = source.folder_id AND target.name = source.name)
    WHEN NOT MATCHED THEN 
      INSERT(
            [folder_id] ,
            [name],
            [description],
            [project_format_version],
            [deployed_by_sid],
            [deployed_by_name],
            [last_deployed_time],
            [created_time],
            [object_version_lsn],
            [validation_status],
            [last_validation_time]) 
      VALUES (
            @folder_id,
            @name,
            @description,
            @project_format_version,
            @deployed_by_sid,
            @deployed_by_name,
            @last_deployed_time,
            @created_time,
            @object_version_lsn,
            @validation_status,
            @last_validation_time);
      
      IF @@ROWCOUNT = 1
      BEGIN
        SET @project_id = scope_identity()
        RETURN 0
      END
      ELSE BEGIN
        SET @project_id = -1
        RETURN 1
      END
