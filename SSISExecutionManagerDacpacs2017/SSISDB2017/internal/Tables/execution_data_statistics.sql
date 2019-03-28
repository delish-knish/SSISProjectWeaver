CREATE TABLE [internal].[execution_data_statistics] (
    [data_stats_id]              BIGINT             IDENTITY (1, 1) NOT NULL,
    [execution_id]               BIGINT             NOT NULL,
    [package_name]               NVARCHAR (260)     NOT NULL,
    [package_location_type]      NVARCHAR (128)     NULL,
    [package_path_full]          NVARCHAR (4000)    NULL,
    [task_name]                  NVARCHAR (4000)    NULL,
    [dataflow_path_id_string]    NVARCHAR (4000)    NULL,
    [dataflow_path_name]         NVARCHAR (4000)    NULL,
    [source_component_name]      NVARCHAR (4000)    NULL,
    [destination_component_name] NVARCHAR (4000)    NULL,
    [rows_sent]                  BIGINT             NULL,
    [created_time]               DATETIMEOFFSET (7) NULL,
    [execution_path]             NVARCHAR (MAX)     NULL,
    CONSTRAINT [PK_Execution_data_statistics] PRIMARY KEY CLUSTERED ([data_stats_id] ASC),
    CONSTRAINT [FK_ExecDataStat_ExecutionId_Executions] FOREIGN KEY ([execution_id]) REFERENCES [internal].[executions] ([execution_id]) ON DELETE CASCADE
);

