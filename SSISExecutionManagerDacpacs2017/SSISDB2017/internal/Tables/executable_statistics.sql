CREATE TABLE [internal].[executable_statistics] (
    [statistics_id]       BIGINT              IDENTITY (1, 1) NOT NULL,
    [execution_id]        BIGINT              NOT NULL,
    [executable_id]       BIGINT              NOT NULL,
    [execution_path]      NVARCHAR (MAX)      NULL,
    [start_time]          DATETIMEOFFSET (7)  NULL,
    [end_time]            DATETIMEOFFSET (7)  NULL,
    [execution_hierarchy] [sys].[hierarchyid] NULL,
    [execution_duration]  INT                 NULL,
    [execution_result]    SMALLINT            NULL,
    [execution_value]     SQL_VARIANT         NULL,
    CONSTRAINT [PK_Executable_statistics] PRIMARY KEY CLUSTERED ([statistics_id] ASC),
    CONSTRAINT [FK_ExecutableStatistics_ExecutableId_Executables] FOREIGN KEY ([executable_id]) REFERENCES [internal].[executables] ([executable_id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ExecutableStatistics_ExecutionId_Executions] FOREIGN KEY ([execution_id]) REFERENCES [internal].[executions] ([execution_id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_ExecutableStatistics_Execution_id]
    ON [internal].[executable_statistics]([execution_id] ASC)
    INCLUDE([statistics_id]);

