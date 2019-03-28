CREATE TABLE [internal].[validations] (
    [validation_id]     BIGINT    NOT NULL,
    [environment_scope] CHAR (1)  NOT NULL,
    [validate_type]     CHAR (1)  NOT NULL,
    [folder_name]       [sysname] NOT NULL,
    [project_name]      [sysname] NOT NULL,
    [project_lsn]       BIGINT    NULL,
    [use32bitruntime]   BIT       NULL,
    [reference_id]      BIGINT    NULL,
    CONSTRAINT [PK_Validations] PRIMARY KEY CLUSTERED ([validation_id] ASC),
    CONSTRAINT [FK_Validations_ValidationId_Operations] FOREIGN KEY ([validation_id]) REFERENCES [internal].[operations] ([operation_id]) ON DELETE CASCADE
);

