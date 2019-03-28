CREATE TABLE [internal].[executions] (
    [execution_id]            BIGINT         NOT NULL,
    [folder_name]             [sysname]      NOT NULL,
    [project_name]            [sysname]      NOT NULL,
    [package_name]            NVARCHAR (260) NOT NULL,
    [reference_id]            BIGINT         NULL,
    [reference_type]          CHAR (1)       NULL,
    [environment_folder_name] NVARCHAR (128) NULL,
    [environment_name]        NVARCHAR (128) NULL,
    [project_lsn]             BIGINT         NULL,
    [executed_as_sid]         VARBINARY (85) NOT NULL,
    [executed_as_name]        NVARCHAR (128) NOT NULL,
    [use32bitruntime]         BIT            NOT NULL,
    CONSTRAINT [PK_Executions] PRIMARY KEY CLUSTERED ([execution_id] ASC),
    CONSTRAINT [FK_Executions_ExecutionId_Operations] FOREIGN KEY ([execution_id]) REFERENCES [internal].[operations] ([operation_id]) ON DELETE CASCADE
);

