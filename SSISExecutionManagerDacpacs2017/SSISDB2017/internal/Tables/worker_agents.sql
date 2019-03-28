CREATE TABLE [internal].[worker_agents] (
    [WorkerAgentId]  UNIQUEIDENTIFIER   NOT NULL,
    [DisplayName]    NVARCHAR (256)     NULL,
    [Description]    NVARCHAR (MAX)     NULL,
    [MachineName]    NVARCHAR (256)     NULL,
    [Tags]           NVARCHAR (MAX)     NULL,
    [UserAccount]    NVARCHAR (256)     NULL,
    [IsEnabled]      BIT                DEFAULT ((0)) NOT NULL,
    [LastOnlineTime] DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    CONSTRAINT [PK_Worker_Agents] PRIMARY KEY CLUSTERED ([WorkerAgentId] ASC)
);

