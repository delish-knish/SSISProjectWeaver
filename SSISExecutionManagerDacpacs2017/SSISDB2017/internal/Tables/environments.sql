CREATE TABLE [internal].[environments] (
    [environment_id]   BIGINT             IDENTITY (1, 1) NOT NULL,
    [environment_name] [sysname]          NOT NULL,
    [folder_id]        BIGINT             NOT NULL,
    [description]      NVARCHAR (1024)    NULL,
    [created_by_sid]   VARBINARY (85)     NOT NULL,
    [created_by_name]  NVARCHAR (128)     NOT NULL,
    [created_time]     DATETIMEOFFSET (7) NOT NULL,
    CONSTRAINT [PK_Environments] PRIMARY KEY CLUSTERED ([environment_id] ASC),
    CONSTRAINT [FK_Environments_FolderId_Folders] FOREIGN KEY ([folder_id]) REFERENCES [internal].[folders] ([folder_id]),
    CONSTRAINT [Unique_Folder_Environment] UNIQUE NONCLUSTERED ([environment_name] ASC, [folder_id] ASC)
);

