CREATE TABLE [internal].[environment_variables] (
    [variable_id]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [environment_id]  BIGINT          NOT NULL,
    [name]            [sysname]       NOT NULL,
    [description]     NVARCHAR (1024) NULL,
    [type]            NVARCHAR (128)  NOT NULL,
    [sensitive]       BIT             NOT NULL,
    [value]           SQL_VARIANT     NULL,
    [sensitive_value] VARBINARY (MAX) NULL,
    [base_data_type]  NVARCHAR (128)  NOT NULL,
    CONSTRAINT [PK_Environment_Variables] PRIMARY KEY CLUSTERED ([variable_id] ASC),
    CONSTRAINT [FK_EnvironmentVariables_EnvironmentId_Environments] FOREIGN KEY ([environment_id]) REFERENCES [internal].[environments] ([environment_id]) ON DELETE CASCADE,
    CONSTRAINT [Unique_Environment_Variable] UNIQUE NONCLUSTERED ([environment_id] ASC, [name] ASC)
);

