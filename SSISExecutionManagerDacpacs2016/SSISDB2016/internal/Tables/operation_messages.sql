CREATE TABLE [internal].[operation_messages] (
    [operation_message_id] BIGINT             IDENTITY (1, 1) NOT NULL,
    [operation_id]         BIGINT             NOT NULL,
    [message_time]         DATETIMEOFFSET (7) NOT NULL,
    [message_type]         SMALLINT           NOT NULL,
    [message_source_type]  SMALLINT           NULL,
    [message]              NVARCHAR (MAX)     NULL,
    [extended_info_id]     BIGINT             NULL,
    CONSTRAINT [PK_Operation_Messages] PRIMARY KEY CLUSTERED ([operation_message_id] ASC),
    CONSTRAINT [FK_OperationMessages_OperationId_Operations] FOREIGN KEY ([operation_id]) REFERENCES [internal].[operations] ([operation_id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_OperationMessages_Operation_id]
    ON [internal].[operation_messages]([operation_id] ASC)
    INCLUDE([operation_message_id]);

