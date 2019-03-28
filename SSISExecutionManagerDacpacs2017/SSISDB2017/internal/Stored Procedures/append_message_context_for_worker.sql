
CREATE PROCEDURE [internal].[append_message_context_for_worker]
        @operation_id       bigint,                             
        @event_message_guid uniqueidentifier,                             
        @context_depth      int,                                
        @package_path       nvarchar(MAX),
        @context_type       smallint,
        @context_source_name nvarchar(MAX),
        @context_source_id   nvarchar(38),
        @property_name       nvarchar(4000),
        @property_value      sql_variant
WITH EXECUTE AS 'AllSchemaOwner'
AS
SET NOCOUNT ON

	DECLARE @IsExist 		   BIT = 0
	declare @event_message_id bigint = null
	select	@IsExist = 1, @event_message_id = [event_message_id] from [event_messages]
	where [event_message_guid] = @event_message_guid
	IF @IsExist = 0
	BEGIN
		RAISERROR(27256, 16, 1, @event_message_id) WITH NOWAIT	
		return 1	
	END

    INSERT INTO [internal].[event_message_context]
           ([operation_id],
           [event_message_id],
           [context_depth],
           [package_path],
           [context_type],
           [context_source_name],
           [context_source_id],
           [property_name],
           [property_value])
     VALUES(
              @operation_id,
              @event_message_id,
              @context_depth,
              @package_path,
              @context_type,
              @context_source_name,
              @context_source_id,
              @property_name,
              @property_value 
           )
    RETURN 0
