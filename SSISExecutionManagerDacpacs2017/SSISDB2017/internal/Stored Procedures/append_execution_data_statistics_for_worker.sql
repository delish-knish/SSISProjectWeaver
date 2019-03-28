
CREATE PROCEDURE [internal].[append_execution_data_statistics_for_worker]
        @execution_id                 bigint,                             
        @package_name                 nvarchar(260),  
        @package_location_type        nvarchar(128),
        @package_path_full            nvarchar(4000),                           
        @task_name                    nvarchar(4000), 
        @dataflow_path_id_string      nvarchar(4000),                               
        @dataflow_path_name           nvarchar(4000),
        @source_component_name        nvarchar(4000),
        @destination_component_name   nvarchar(4000),
        @rows_sent                    bigint,
        @created_time                 datetimeoffset,
        @execution_path               nvarchar(MAX)
WITH EXECUTE AS 'AllSchemaOwner'
AS
SET NOCOUNT ON

    INSERT INTO [internal].[execution_data_statistics]
           ([execution_id],
            [package_name],
            [package_location_type],
            [package_path_full],
            [task_name],
            [dataflow_path_id_string],
            [dataflow_path_name],
            [source_component_name],
            [destination_component_name],
            [rows_sent],
            [created_time],
            [execution_path])
     VALUES(
            @execution_id,                             
            @package_name,                              
            @package_location_type,
            @package_path_full,
            @task_name,
            @dataflow_path_id_string,                             
            @dataflow_path_name,
            @source_component_name,
            @destination_component_name,
            @rows_sent,
            @created_time,
            @execution_path
           )
    RETURN 0
