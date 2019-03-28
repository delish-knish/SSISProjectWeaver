CREATE TABLE [internal].[executables] (
    [executable_id]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [project_id]            BIGINT          NOT NULL,
    [project_version_lsn]   BIGINT          NOT NULL,
    [package_name]          NVARCHAR (260)  NOT NULL,
    [package_location_type] NVARCHAR (128)  NULL,
    [package_path_full]     NVARCHAR (4000) NULL,
    [executable_name]       NVARCHAR (4000) NULL,
    [executable_guid]       NVARCHAR (38)   NULL,
    [package_path]          NVARCHAR (MAX)  NULL,
    CONSTRAINT [PK_Executables] PRIMARY KEY CLUSTERED ([executable_id] ASC),
    CONSTRAINT [FK_Executables] FOREIGN KEY ([project_id]) REFERENCES [internal].[projects] ([project_id]) ON DELETE CASCADE
);

