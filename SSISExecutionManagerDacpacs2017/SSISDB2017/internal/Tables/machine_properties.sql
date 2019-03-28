CREATE TABLE [internal].[machine_properties] (
    [WorkerAgentId] UNIQUEIDENTIFIER NOT NULL,
    [PropertyName]  NVARCHAR (256)   NOT NULL,
    [PropertyValue] NVARCHAR (MAX)   NULL,
    CONSTRAINT [PK_machine_properties] PRIMARY KEY CLUSTERED ([WorkerAgentId] ASC, [PropertyName] ASC),
    CONSTRAINT [FK_machine_properties_WorkerAgentId] FOREIGN KEY ([WorkerAgentId]) REFERENCES [internal].[worker_agents] ([WorkerAgentId]) ON DELETE CASCADE
);

