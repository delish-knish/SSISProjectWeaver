CREATE TABLE [ctl].[ETLBatchExecution]
  (
     [ETLBatchExecutionId]								  INT IDENTITY(1, 1) NOT NULL
     ,[CallingJobName]                                    VARCHAR(250) NOT NULL
     ,[SSISEnvironmentName]                               VARCHAR(128)
     ,[ETLBatchId]										  INT CONSTRAINT [DF_ETLBatchExecution_ETLBatchId] DEFAULT (0) NOT NULL
     ,[StartDateTime]                                     DATETIME2 CONSTRAINT [DF_ETLBatchExecution_StartDateTime] DEFAULT (GETDATE()) NOT NULL
     ,[EndDateTime]                                       DATETIME2 NULL
     ,[ExecutionDurationInMinutes] AS DATEDIFF(MINUTE, StartDateTime, EndDateTime)
     ,[DayOfWeekName] AS DATENAME (WEEKDAY, [StartDateTime])
	 --,[ETLBatchPhaseId]									  INT NULL
     ,[ETLBatchStatusId]                                  INT NULL
     ,[TotalEntryPointPackageCount]                       SMALLINT NULL
     ,[TotalRemainingEntryPointPackageCount]              SMALLINT NULL
     ,[TotalETLPackageCount]                              SMALLINT NULL
     ,[TotalRemainingETLPackageCount]                     SMALLINT NULL
     ,[CreatedDate]                                       DATETIME2 (7) CONSTRAINT [DF_ETLBatchExecution_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                                       VARCHAR (50) CONSTRAINT [DF_ETLBatchExecution_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]                                   DATETIME2 (7) CONSTRAINT [DF_ETLBatchExecution_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]                                   VARCHAR (50) CONSTRAINT [DF_ETLBatchExecution_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLBatchExecution] PRIMARY KEY ([ETLBatchExecutionId]),
     CONSTRAINT [FK_ETLBatchExecution_ETLBatchStatus] FOREIGN KEY (ETLBatchStatusId) REFERENCES ref.ETLBatchStatus([ETLBatchStatusId]), 
    CONSTRAINT [FK_ETLBatchExecution_ETLBatch] FOREIGN KEY ([ETLBatchId]) REFERENCES ctl.[ETLBatch]([ETLBatchId]), 
    --CONSTRAINT [FK_ETLBatchExecution_ETLBatchPhase] FOREIGN KEY (ETLBatchPhaseId) REFERENCES ctl.ETLBatchPhase(ETLBatchPhaseId),
  )

GO

CREATE INDEX [IX_ETLBatch_ETLBatchStatusId]
  ON [ctl].[ETLBatchExecution] (ETLBatchStatusId) 
