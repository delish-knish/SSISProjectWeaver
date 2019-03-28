CREATE TABLE [internal].[execution_component_phases] (
    [phase_stats_id]        BIGINT             IDENTITY (1, 1) NOT NULL,
    [execution_id]          BIGINT             NOT NULL,
    [package_name]          NVARCHAR (260)     NOT NULL,
    [package_location_type] NVARCHAR (128)     NULL,
    [package_path_full]     NVARCHAR (4000)    NULL,
    [task_name]             NVARCHAR (4000)    NOT NULL,
    [subcomponent_name]     NVARCHAR (4000)    NULL,
    [phase]                 [sysname]          NOT NULL,
    [is_start]              BIT                NULL,
    [phase_time]            DATETIMEOFFSET (7) NULL,
    [execution_path]        NVARCHAR (MAX)     NULL,
    [sequence_id]           INT                NULL,
    CONSTRAINT [PK_Execution_component_phases] PRIMARY KEY CLUSTERED ([phase_stats_id] ASC),
    CONSTRAINT [FK_ExecCompPhases_ExecutionId_Executions] FOREIGN KEY ([execution_id]) REFERENCES [internal].[executions] ([execution_id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [Unique_sequence_id]
    ON [internal].[execution_component_phases]([execution_id] ASC, [sequence_id] ASC);

