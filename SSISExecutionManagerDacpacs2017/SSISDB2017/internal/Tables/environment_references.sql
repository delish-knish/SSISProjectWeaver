CREATE TABLE [internal].[environment_references] (
    [reference_id]            BIGINT             IDENTITY (1, 1) NOT NULL,
    [project_id]              BIGINT             NOT NULL,
    [reference_type]          CHAR (1)           NOT NULL,
    [environment_folder_name] NVARCHAR (128)     NULL,
    [environment_name]        [sysname]          NOT NULL,
    [validation_status]       CHAR (1)           NOT NULL,
    [last_validation_time]    DATETIMEOFFSET (7) NULL,
    CONSTRAINT [PK_environment_references] PRIMARY KEY CLUSTERED ([reference_id] ASC),
    CONSTRAINT [FK_ProjectEnvironment_ProjectId_Projects] FOREIGN KEY ([project_id]) REFERENCES [internal].[projects] ([project_id]) ON DELETE CASCADE
);

