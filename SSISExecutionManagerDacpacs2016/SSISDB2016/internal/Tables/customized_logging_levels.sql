CREATE TABLE [internal].[customized_logging_levels] (
    [level_id]        BIGINT             IDENTITY (1, 1) NOT NULL,
    [name]            [sysname]          NOT NULL,
    [description]     NVARCHAR (1024)    NULL,
    [profile_value]   BIGINT             NOT NULL,
    [events_value]    BIGINT             NOT NULL,
    [created_by_sid]  VARBINARY (85)     NOT NULL,
    [created_by_name] NVARCHAR (128)     NOT NULL,
    [created_time]    DATETIMEOFFSET (7) NOT NULL,
    CONSTRAINT [PK_Levels] PRIMARY KEY CLUSTERED ([level_id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unique_level_name]
    ON [internal].[customized_logging_levels]([name] ASC);

