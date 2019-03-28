CREATE TABLE [internal].[folders] (
    [folder_id]       BIGINT             IDENTITY (1, 1) NOT NULL,
    [name]            [sysname]          NOT NULL,
    [description]     NVARCHAR (1024)    NULL,
    [created_by_sid]  VARBINARY (85)     NOT NULL,
    [created_by_name] NVARCHAR (128)     NOT NULL,
    [created_time]    DATETIMEOFFSET (7) NOT NULL,
    CONSTRAINT [PK_Folders] PRIMARY KEY CLUSTERED ([folder_id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unique_folder_name]
    ON [internal].[folders]([name] ASC);

