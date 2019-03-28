CREATE TABLE [internal].[operation_messages_scaleout] (
    [operation_id]        BIGINT             NOT NULL,
    [message_time]        DATETIMEOFFSET (7) NOT NULL,
    [message_type]        SMALLINT           NOT NULL,
    [message_source_type] SMALLINT           NULL,
    [message]             NVARCHAR (MAX)     NULL,
    [extended_info_id]    BIGINT             NULL,
    [event_message_guid]  UNIQUEIDENTIFIER   NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_OperationMessagesScaleout_event_message_guid]
    ON [internal].[operation_messages_scaleout]([event_message_guid] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_OperationMessagesScaleout_Operation_id]
    ON [internal].[operation_messages_scaleout]([operation_id] ASC);

