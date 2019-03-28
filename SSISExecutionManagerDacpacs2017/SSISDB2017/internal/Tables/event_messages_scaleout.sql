CREATE TABLE [internal].[event_messages_scaleout] (
    [operation_id]          BIGINT           NOT NULL,
    [execution_path]        NVARCHAR (MAX)   NULL,
    [package_name]          NVARCHAR (260)   NULL,
    [package_location_type] NVARCHAR (128)   NULL,
    [package_path_full]     NVARCHAR (4000)  NULL,
    [event_name]            NVARCHAR (1024)  NULL,
    [message_source_name]   NVARCHAR (4000)  NULL,
    [message_source_id]     NVARCHAR (38)    NULL,
    [subcomponent_name]     NVARCHAR (4000)  NULL,
    [package_path]          NVARCHAR (MAX)   NULL,
    [threadID]              INT              NOT NULL,
    [message_code]          INT              NULL,
    [event_message_guid]    UNIQUEIDENTIFIER NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_EventMessagesScaleout_Guid]
    ON [internal].[event_messages_scaleout]([event_message_guid] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventMessagesScaleout_Operation_id]
    ON [internal].[event_messages_scaleout]([operation_id] ASC);

