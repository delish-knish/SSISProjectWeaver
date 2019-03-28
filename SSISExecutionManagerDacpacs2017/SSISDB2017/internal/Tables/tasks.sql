CREATE TABLE [internal].[tasks] (
    [TaskId]               UNIQUEIDENTIFIER   NOT NULL,
    [JobId]                UNIQUEIDENTIFIER   NULL,
    [TaskType]             INT                NOT NULL,
    [InputData]            NVARCHAR (MAX)     DEFAULT (NULL) NULL,
    [MaxExecutedCount]     INT                DEFAULT ((1)) NOT NULL,
    [ExecutedCount]        INT                DEFAULT ((0)) NOT NULL,
    [Status]               INT                NOT NULL,
    [IsCritical]           BIT                DEFAULT ((0)) NULL,
    [Priority]             INT                DEFAULT ((0)) NOT NULL,
    [ReadyForDispatchTime] DATETIMEOFFSET (7) NULL,
    [LastUpdatedTime]      DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedTime]          DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [WorkerAgentId]        UNIQUEIDENTIFIER   NULL,
    [ExpiredTime]          DATETIMEOFFSET (7) DEFAULT (NULL) NULL,
    [CreateWorkerAgentId]  UNIQUEIDENTIFIER   DEFAULT (NULL) NULL,
    [IsCancelled]          BIT                DEFAULT ((0)) NULL,
    [LastPickupTime]       DATETIMEOFFSET (7) NULL,
    PRIMARY KEY CLUSTERED ([TaskId] ASC),
    CONSTRAINT [Chk_MaxExecutedCount_GreaterOrEqualOne] CHECK ([MaxExecutedCount]>(0)),
    CONSTRAINT [FK_tasks_JobId] FOREIGN KEY ([JobId]) REFERENCES [internal].[jobs] ([JobId]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [index_tasks_ReadyForDispatchTime]
    ON [internal].[tasks]([ReadyForDispatchTime] ASC)
    INCLUDE([CreatedTime], [CreateWorkerAgentId], [ExecutedCount], [ExpiredTime], [InputData], [IsCritical], [JobId], [LastUpdatedTime], [MaxExecutedCount], [Priority], [Status], [TaskType]);


GO
CREATE NONCLUSTERED INDEX [index_tasks_Status]
    ON [internal].[tasks]([Status] ASC)
    INCLUDE([ExecutedCount], [ExpiredTime], [IsCancelled], [MaxExecutedCount], [WorkerAgentId]);

