
CREATE PROCEDURE [internal].[append_event_message_for_worker]
        @operation_id       bigint,                             
        @message_type       int,                                
        @message_time         datetimeoffset,                     
        @message_source       smallint,                           
        @message              nvarchar(max),                      
        @extended_info_id     bigint = NULL,
        @package_name         nvarchar(260),
        @package_location_type nvarchar(128),
		@package_path_full    nvarchar(4000),
        @event_name           nvarchar(1024),
        @message_source_name  nvarchar(4000),
        @message_source_id    nvarchar(38),
        @subcomponent_name    nvarchar(4000),
        @package_path         nvarchar(MAX),
        @execution_path       nvarchar(MAX),
        @thread_id            int,
        @message_code         int,
        @event_message_guid	  uniqueidentifier
WITH EXECUTE AS 'AllSchemaOwner'
AS
SET NOCOUNT ON

    DECLARE @operation_message_id   bigint    

    INSERT INTO [internal].[operation_messages] 
           ([operation_id], 
            [message_type], 
            [message_time],
            [message_source_type], 
            [message], 
            [extended_info_id])
        VALUES(
            @operation_id,  
            @message_type,
            @message_time,
            @message_source,
            @message,
            @extended_info_id)
            
    SET @operation_message_id = SCOPE_IDENTITY()

    INSERT INTO [internal].[event_messages]
           ([operation_id],
           [event_message_id],
           [package_name],
		   [package_location_type],
		   [package_path_full],
           [event_name],
           [message_source_name],
           [message_source_id],
           [subcomponent_name],
           [package_path],
           [execution_path],
           [threadID],
           [message_code],
		   [event_message_guid]
		   )
     VALUES
           (
           @operation_id,
           @operation_message_id,
           @package_name,
           @package_location_type,
           @package_path_full,
           @event_name,
           @message_source_name,
           @message_source_id,
           @subcomponent_name,
           @package_path,
           @execution_path,
           @thread_id,
           @message_code,
		   @event_message_guid
           )
    RETURN 0
