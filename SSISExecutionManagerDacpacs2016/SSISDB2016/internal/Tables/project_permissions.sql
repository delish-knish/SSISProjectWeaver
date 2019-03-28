CREATE TABLE [internal].[project_permissions] (
    [id]              BIGINT               IDENTITY (1, 1) NOT NULL,
    [sid]             [internal].[adt_sid] NOT NULL,
    [object_id]       BIGINT               NOT NULL,
    [permission_type] SMALLINT             NOT NULL,
    [is_role]         BIT                  NOT NULL,
    [is_deny]         BIT                  NOT NULL,
    [grantor_sid]     [internal].[adt_sid] NOT NULL,
    CONSTRAINT [PK_Project_Permissions] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [CK_Project_PermissionType] CHECK ([permission_type]=(4) OR [permission_type]=(3) OR [permission_type]=(2) OR [permission_type]=(1)),
    CONSTRAINT [FK_ProjectPermissions_ObjectId_Projects] FOREIGN KEY ([object_id]) REFERENCES [internal].[projects] ([project_id]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unique_ProjectPermissions]
    ON [internal].[project_permissions]([object_id] ASC, [permission_type] ASC, [sid] ASC);

