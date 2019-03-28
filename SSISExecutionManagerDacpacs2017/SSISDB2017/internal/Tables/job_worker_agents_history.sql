CREATE TABLE [internal].[job_worker_agents_history] (
    [WorkerAgentId] UNIQUEIDENTIFIER NOT NULL,
    [JobId]         UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_job_worker_agents_history] PRIMARY KEY CLUSTERED ([JobId] ASC, [WorkerAgentId] ASC),
    CONSTRAINT [FK_job_worker_agents_history_JobId] FOREIGN KEY ([JobId]) REFERENCES [internal].[jobs] ([JobId]) ON DELETE CASCADE
);

