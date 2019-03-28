CREATE TABLE [internal].[object_parameters] (
    [parameter_id]             BIGINT             IDENTITY (1, 1) NOT NULL,
    [project_id]               BIGINT             NOT NULL,
    [project_version_lsn]      BIGINT             NOT NULL,
    [object_type]              SMALLINT           NOT NULL,
    [object_name]              NVARCHAR (260)     NOT NULL,
    [parameter_name]           [sysname]          NOT NULL,
    [parameter_data_type]      NVARCHAR (128)     NOT NULL,
    [required]                 BIT                NOT NULL,
    [sensitive]                BIT                NOT NULL,
    [description]              NVARCHAR (1024)    NULL,
    [design_default_value]     SQL_VARIANT        NULL,
    [default_value]            SQL_VARIANT        NULL,
    [sensitive_default_value]  VARBINARY (MAX)    NULL,
    [base_data_type]           NVARCHAR (128)     NULL,
    [value_type]               CHAR (1)           NOT NULL,
    [value_set]                BIT                NOT NULL,
    [referenced_variable_name] NVARCHAR (128)     NULL,
    [validation_status]        CHAR (1)           NOT NULL,
    [last_validation_time]     DATETIMEOFFSET (7) NULL,
    CONSTRAINT [PK_Object_Parameters] PRIMARY KEY CLUSTERED ([parameter_id] ASC),
    CONSTRAINT [FK_ObjectParameters_ProjectId_Projects] FOREIGN KEY ([project_id]) REFERENCES [internal].[projects] ([project_id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ObjectParameters_ProjectVersionLsn_ObjectVersions] FOREIGN KEY ([project_version_lsn]) REFERENCES [internal].[object_versions] ([object_version_lsn]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_internal_object_parameters_inc]
    ON [internal].[object_parameters]([project_id] ASC, [project_version_lsn] ASC);

