CREATE TABLE [internal].[packages] (
    [package_id]             BIGINT             IDENTITY (1, 1) NOT NULL,
    [project_version_lsn]    BIGINT             NOT NULL,
    [name]                   NVARCHAR (260)     NOT NULL,
    [package_guid]           UNIQUEIDENTIFIER   NOT NULL,
    [description]            NVARCHAR (1024)    NULL,
    [package_format_version] INT                NOT NULL,
    [version_major]          INT                NOT NULL,
    [version_minor]          INT                NOT NULL,
    [version_build]          INT                NOT NULL,
    [version_comments]       NVARCHAR (1024)    NULL,
    [version_guid]           UNIQUEIDENTIFIER   NOT NULL,
    [project_id]             BIGINT             NOT NULL,
    [entry_point]            BIT                NOT NULL,
    [validation_status]      CHAR (1)           NOT NULL,
    [last_validation_time]   DATETIMEOFFSET (7) NULL,
    [package_data]           VARBINARY (MAX)    NULL,
    CONSTRAINT [PK_Packages] PRIMARY KEY CLUSTERED ([package_id] ASC),
    CONSTRAINT [FK_Packages_ProjectId_Projects] FOREIGN KEY ([project_id]) REFERENCES [internal].[projects] ([project_id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Packages_ProjectVersionLsn_ObjectVersions] FOREIGN KEY ([project_version_lsn]) REFERENCES [internal].[object_versions] ([object_version_lsn]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_Packages_Name]
    ON [internal].[packages]([name] ASC)
    INCLUDE([package_id], [project_version_lsn], [project_id]);

