CREATE TABLE [internal].[event_message_context] (
    [context_id]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [operation_id]        BIGINT          NOT NULL,
    [event_message_id]    BIGINT          NOT NULL,
    [context_depth]       INT             NULL,
    [package_path]        NVARCHAR (MAX)  NULL,
    [context_type]        SMALLINT        NULL,
    [context_source_name] NVARCHAR (4000) NULL,
    [context_source_id]   NVARCHAR (38)   NULL,
    [property_name]       NVARCHAR (4000) NULL,
    [property_value]      SQL_VARIANT     NULL,
    CONSTRAINT [PK_Event_Message_Context] PRIMARY KEY CLUSTERED ([context_id] ASC),
    CONSTRAINT [FK_EventMessageContext_EventMessageId_EventMessages] FOREIGN KEY ([event_message_id]) REFERENCES [internal].[event_messages] ([event_message_id]) ON DELETE CASCADE,
    CONSTRAINT [FK_EventMessagecontext_Operations] FOREIGN KEY ([operation_id]) REFERENCES [internal].[operations] ([operation_id])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventMessageContext_Operation_id]
    ON [internal].[event_message_context]([operation_id] ASC, [event_message_id] ASC)
    INCLUDE([context_id]);

