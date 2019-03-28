CREATE TABLE [internal].[jobs] (
    [JobId]           UNIQUEIDENTIFIER   NOT NULL,
    [IsCancelled]     BIT                DEFAULT ((0)) NOT NULL,
    [CreatedTime]     DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [JobType]         INT                NOT NULL,
    [InputData]       NVARCHAR (MAX)     DEFAULT (NULL) NULL,
    [Creator]         NVARCHAR (256)     NOT NULL,
    [Priority]        INT                DEFAULT ((0)) NOT NULL,
    [LastUpdatedTime] DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    CONSTRAINT [PK_Jobs] PRIMARY KEY CLUSTERED ([JobId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [index_job_iscancelled]
    ON [internal].[jobs]([IsCancelled] ASC);

