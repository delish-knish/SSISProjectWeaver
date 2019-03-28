CREATE TABLE [internal].[event_message_context_scaleout] (
    [context_id]          BIGINT           IDENTITY (1, 1) NOT NULL,
    [operation_id]        BIGINT           NOT NULL,
    [context_depth]       INT              NULL,
    [package_path]        NVARCHAR (MAX)   NULL,
    [context_type]        SMALLINT         NULL,
    [context_source_name] NVARCHAR (4000)  NULL,
    [context_source_id]   NVARCHAR (38)    NULL,
    [property_name]       NVARCHAR (4000)  NULL,
    [property_value]      SQL_VARIANT      NULL,
    [event_message_guid]  UNIQUEIDENTIFIER NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_EventMessageContextScaleout_Operation_id]
    ON [internal].[event_message_context_scaleout]([operation_id] ASC, [event_message_guid] ASC)
    INCLUDE([context_id]);

