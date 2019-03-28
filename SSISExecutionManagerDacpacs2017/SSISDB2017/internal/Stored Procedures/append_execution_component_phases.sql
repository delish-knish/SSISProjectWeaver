


CREATE PROCEDURE [internal].[append_execution_component_phases]
        @execution_id                 bigint,                             
        @package_name                 nvarchar(260),
        @package_location_type        nvarchar(128),
        @package_path_full            nvarchar(4000),                            
        @task_name                    nvarchar(4000),                                
        @subcomponent_name            nvarchar(4000),
        @phase                        sysname,
        @is_start                     bit,
        @start_phase_time             datetimeoffset,
        @end_phase_time               datetimeoffset,
        @execution_path               nvarchar(MAX),
        @sequence_id                  int
AS
SET NOCOUNT ON

    IF [internal].[check_permission] 
    (
        4,
        @execution_id,
        2
    ) = 0
    BEGIN
        RAISERROR(27143, 16, 5, @execution_id) WITH NOWAIT;
        RETURN 1;      
    END
	
    DECLARE @phase_time datetimeoffset
    SET @phase_time = NULL;

    IF(@is_start = 'False')
    BEGIN
        UPDATE [internal].[execution_component_phases] 
        SET [phase_time] = @start_phase_time
        WHERE [sequence_id] = @sequence_id 
        AND [execution_id] = @execution_id;

        SET @phase_time = @end_phase_time;
    END

    INSERT INTO [internal].[execution_component_phases]
           ([execution_id],
            [package_name],
            [package_location_type],
            [package_path_full],
            [task_name],
            [subcomponent_name],
            [phase],
            [is_start],
            [phase_time], 
            [execution_path],
            [sequence_id])
     VALUES(
            @execution_id,                             
            @package_name, 
            @package_location_type,
            @package_path_full,                              
            @task_name,                                
            @subcomponent_name,
            @phase,
            @is_start,
            @phase_time,
            @execution_path,
	    @sequence_id
           )
    RETURN 0
