CREATE TABLE [internal].[operations] (
    [operation_id]    BIGINT             IDENTITY (1, 1) NOT NULL,
    [operation_type]  SMALLINT           NOT NULL,
    [created_time]    DATETIMEOFFSET (7) NULL,
    [object_type]     SMALLINT           NULL,
    [object_id]       BIGINT             NULL,
    [object_name]     NVARCHAR (260)     NULL,
    [status]          INT                NOT NULL,
    [start_time]      DATETIMEOFFSET (7) NULL,
    [end_time]        DATETIMEOFFSET (7) NULL,
    [caller_sid]      VARBINARY (85)     NOT NULL,
    [caller_name]     [sysname]          NOT NULL,
    [process_id]      INT                NULL,
    [stopped_by_sid]  VARBINARY (85)     NULL,
    [stopped_by_name] NVARCHAR (128)     NULL,
    [operation_guid]  UNIQUEIDENTIFIER   NULL,
    [server_name]     NVARCHAR (128)     NULL,
    [machine_name]    NVARCHAR (128)     NULL,
    CONSTRAINT [PK_Operations] PRIMARY KEY CLUSTERED ([operation_id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Operations_object_id]
    ON [internal].[operations]([object_id] ASC);

