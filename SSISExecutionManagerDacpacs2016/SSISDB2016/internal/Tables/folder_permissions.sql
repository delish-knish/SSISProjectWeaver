CREATE TABLE [internal].[folder_permissions] (
    [id]              BIGINT               IDENTITY (1, 1) NOT NULL,
    [sid]             [internal].[adt_sid] NOT NULL,
    [object_id]       BIGINT               NOT NULL,
    [permission_type] SMALLINT             NOT NULL,
    [is_role]         BIT                  NOT NULL,
    [is_deny]         BIT                  NOT NULL,
    [grantor_sid]     [internal].[adt_sid] NOT NULL,
    CONSTRAINT [PK_Folder_Permissions] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [CK_Folder_PermissionType] CHECK ([permission_type]=(104) OR [permission_type]=(103) OR [permission_type]=(102) OR [permission_type]=(101) OR [permission_type]=(100) OR [permission_type]=(4) OR [permission_type]=(2) OR [permission_type]=(1)),
    CONSTRAINT [FK_FolderPermissions_ObjectId_Folders] FOREIGN KEY ([object_id]) REFERENCES [internal].[folders] ([folder_id]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unique_FolderPermissions]
    ON [internal].[folder_permissions]([object_id] ASC, [permission_type] ASC, [sid] ASC);

