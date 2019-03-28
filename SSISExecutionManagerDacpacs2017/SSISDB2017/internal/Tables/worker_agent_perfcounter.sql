CREATE TABLE [internal].[worker_agent_perfcounter] (
    [WorkerAgentId]    UNIQUEIDENTIFIER   NOT NULL,
    [PerfCounterName]  NVARCHAR (MAX)     NOT NULL,
    [PerfCounterValue] FLOAT (53)         NOT NULL,
    [TimeStamp]        DATETIMEOFFSET (7) NOT NULL,
    CONSTRAINT [FK_worker_agent_perfcounter_WorkerAgentId] FOREIGN KEY ([WorkerAgentId]) REFERENCES [internal].[worker_agents] ([WorkerAgentId]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [index_worker_agent_perfcounter_TimeStampAndWorkerAgentId]
    ON [internal].[worker_agent_perfcounter]([WorkerAgentId] ASC, [TimeStamp] ASC);

