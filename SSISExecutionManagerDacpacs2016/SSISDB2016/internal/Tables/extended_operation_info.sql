CREATE TABLE [internal].[extended_operation_info] (
    [info_id]      BIGINT             IDENTITY (1, 1) NOT NULL,
    [operation_id] BIGINT             NOT NULL,
    [object_name]  NVARCHAR (260)     NOT NULL,
    [object_type]  SMALLINT           NULL,
    [reference_id] BIGINT             NULL,
    [status]       INT                NOT NULL,
    [start_time]   DATETIMEOFFSET (7) NOT NULL,
    [end_time]     DATETIMEOFFSET (7) NULL,
    CONSTRAINT [PK_Operation_Info] PRIMARY KEY CLUSTERED ([info_id] ASC),
    CONSTRAINT [FK_OperationInfo_Operations] FOREIGN KEY ([operation_id]) REFERENCES [internal].[operations] ([operation_id]) ON DELETE CASCADE
);

