CREATE TYPE [internal].[PackageTableType] AS TABLE (
    [name]                   NVARCHAR (260)     NOT NULL,
    [package_guid]           UNIQUEIDENTIFIER   NOT NULL,
    [description]            NVARCHAR (1024)    NULL,
    [package_format_version] INT                NOT NULL,
    [version_major]          INT                NOT NULL,
    [version_minor]          INT                NOT NULL,
    [version_build]          INT                NOT NULL,
    [version_comments]       NVARCHAR (1024)    NULL,
    [version_guid]           UNIQUEIDENTIFIER   NOT NULL,
    [entry_point]            BIT                NOT NULL,
    [validation_status]      CHAR (1)           NOT NULL,
    [last_validation_time]   DATETIMEOFFSET (7) NULL,
    [package_data]           VARBINARY (MAX)    NULL);

