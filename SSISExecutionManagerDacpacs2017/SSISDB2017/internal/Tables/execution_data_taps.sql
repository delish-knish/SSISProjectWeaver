CREATE TABLE [internal].[execution_data_taps] (
    [data_tap_id]             BIGINT           IDENTITY (1, 1) NOT NULL,
    [execution_id]            BIGINT           NOT NULL,
    [package_path]            NVARCHAR (MAX)   NULL,
    [dataflow_path_id_string] NVARCHAR (4000)  NULL,
    [dataflow_task_guid]      UNIQUEIDENTIFIER NULL,
    [max_rows]                INT              NULL,
    [filename]                NVARCHAR (4000)  NULL,
    CONSTRAINT [PK_Execution_data_taps] PRIMARY KEY CLUSTERED ([data_tap_id] ASC),
    CONSTRAINT [FK_ExecDataTaps_ExecutionId_Executions] FOREIGN KEY ([execution_id]) REFERENCES [internal].[executions] ([execution_id]) ON DELETE CASCADE
);

