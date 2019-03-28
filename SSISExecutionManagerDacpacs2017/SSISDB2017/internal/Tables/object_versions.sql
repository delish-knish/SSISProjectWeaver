CREATE TABLE [internal].[object_versions] (
    [object_version_lsn] BIGINT             IDENTITY (1, 1) NOT NULL,
    [object_id]          BIGINT             NOT NULL,
    [object_type]        SMALLINT           NOT NULL,
    [description]        NVARCHAR (1024)    NULL,
    [created_by]         NVARCHAR (128)     NOT NULL,
    [created_time]       DATETIMEOFFSET (7) NOT NULL,
    [restored_by]        NVARCHAR (128)     NULL,
    [last_restored_time] DATETIMEOFFSET (7) NULL,
    [object_data]        VARBINARY (MAX)    NOT NULL,
    [object_status]      CHAR (1)           NOT NULL,
    CONSTRAINT [PK_Object_Versions] PRIMARY KEY CLUSTERED ([object_version_lsn] ASC)
);

