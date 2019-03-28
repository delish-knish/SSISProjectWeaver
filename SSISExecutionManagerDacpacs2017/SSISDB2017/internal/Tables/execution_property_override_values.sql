CREATE TABLE [internal].[execution_property_override_values] (
    [property_id]              BIGINT          IDENTITY (1, 1) NOT NULL,
    [execution_id]             BIGINT          NOT NULL,
    [property_path]            NVARCHAR (4000) NOT NULL,
    [property_value]           NVARCHAR (MAX)  NULL,
    [sensitive_property_value] VARBINARY (MAX) NULL,
    [sensitive]                BIT             NOT NULL,
    CONSTRAINT [PK_Execution_Property_Override_Value] PRIMARY KEY CLUSTERED ([property_id] ASC),
    CONSTRAINT [FK_ExecutionPropertyOverrideValue_ExecutionId_Executions] FOREIGN KEY ([execution_id]) REFERENCES [internal].[executions] ([execution_id]) ON DELETE CASCADE
);

