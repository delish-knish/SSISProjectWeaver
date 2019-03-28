CREATE TABLE [internal].[job_worker_agents] (
    [WorkerAgentId] UNIQUEIDENTIFIER NOT NULL,
    [JobId]         UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_job_worker_agents] PRIMARY KEY CLUSTERED ([JobId] ASC, [WorkerAgentId] ASC),
    CONSTRAINT [FK_job_worker_agents_JobId] FOREIGN KEY ([JobId]) REFERENCES [internal].[jobs] ([JobId]) ON DELETE CASCADE
);

