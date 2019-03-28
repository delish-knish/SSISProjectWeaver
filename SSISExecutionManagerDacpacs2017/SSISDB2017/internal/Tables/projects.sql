CREATE TABLE [internal].[projects] (
    [project_id]             BIGINT             IDENTITY (1, 1) NOT NULL,
    [folder_id]              BIGINT             NOT NULL,
    [name]                   [sysname]          NOT NULL,
    [description]            NVARCHAR (1024)    NULL,
    [project_format_version] INT                NULL,
    [deployed_by_sid]        VARBINARY (85)     NOT NULL,
    [deployed_by_name]       NVARCHAR (128)     NOT NULL,
    [last_deployed_time]     DATETIMEOFFSET (7) NOT NULL,
    [created_time]           DATETIMEOFFSET (7) NOT NULL,
    [object_version_lsn]     BIGINT             NOT NULL,
    [validation_status]      CHAR (1)           NOT NULL,
    [last_validation_time]   DATETIMEOFFSET (7) NULL,
    CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED ([project_id] ASC),
    CONSTRAINT [FK_Projects_FolderId_Folders] FOREIGN KEY ([folder_id]) REFERENCES [internal].[folders] ([folder_id]),
    CONSTRAINT [Unique_Project_FolderName] UNIQUE NONCLUSTERED ([name] ASC, [folder_id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Projects_Name]
    ON [internal].[projects]([name] ASC)
    INCLUDE([project_id], [folder_id], [object_version_lsn]);

