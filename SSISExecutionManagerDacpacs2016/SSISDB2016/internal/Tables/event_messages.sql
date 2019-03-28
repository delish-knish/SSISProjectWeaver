CREATE TABLE [internal].[event_messages] (
    [event_message_id]      BIGINT          NOT NULL,
    [operation_id]          BIGINT          NOT NULL,
    [execution_path]        NVARCHAR (MAX)  NULL,
    [package_name]          NVARCHAR (260)  NULL,
    [package_location_type] NVARCHAR (128)  NULL,
    [package_path_full]     NVARCHAR (4000) NULL,
    [event_name]            NVARCHAR (1024) NULL,
    [message_source_name]   NVARCHAR (4000) NULL,
    [message_source_id]     NVARCHAR (38)   NULL,
    [subcomponent_name]     NVARCHAR (4000) NULL,
    [package_path]          NVARCHAR (MAX)  NULL,
    [threadID]              INT             NOT NULL,
    [message_code]          INT             NULL,
    CONSTRAINT [PK_Event_Messages] PRIMARY KEY CLUSTERED ([event_message_id] ASC),
    CONSTRAINT [FK_EventMessage_Operations] FOREIGN KEY ([operation_id]) REFERENCES [internal].[operations] ([operation_id]),
    CONSTRAINT [FK_EventMessages_OperationMessageId_OperationMessage] FOREIGN KEY ([event_message_id]) REFERENCES [internal].[operation_messages] ([operation_message_id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_EventMessages_Operation_id]
    ON [internal].[event_messages]([operation_id] ASC);

