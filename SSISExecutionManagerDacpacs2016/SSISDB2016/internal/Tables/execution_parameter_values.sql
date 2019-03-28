CREATE TABLE [internal].[execution_parameter_values] (
    [execution_parameter_id]    BIGINT          IDENTITY (1, 1) NOT NULL,
    [execution_id]              BIGINT          NOT NULL,
    [object_type]               SMALLINT        NOT NULL,
    [parameter_data_type]       NVARCHAR (128)  NOT NULL,
    [parameter_name]            [sysname]       NOT NULL,
    [parameter_value]           SQL_VARIANT     NULL,
    [sensitive_parameter_value] VARBINARY (MAX) NULL,
    [base_data_type]            NVARCHAR (128)  NULL,
    [sensitive]                 BIT             NOT NULL,
    [required]                  BIT             NOT NULL,
    [value_set]                 BIT             NOT NULL,
    [runtime_override]          BIT             NOT NULL,
    CONSTRAINT [PK_Execution_Parameter_value] PRIMARY KEY CLUSTERED ([execution_parameter_id] ASC),
    CONSTRAINT [FK_ExecutionParameterValue_ExecutionId_Executions] FOREIGN KEY ([execution_id]) REFERENCES [internal].[executions] ([execution_id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_ExecutionParameterValue_ExecutionId]
    ON [internal].[execution_parameter_values]([execution_id] ASC);

