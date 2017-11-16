CREATE TABLE [log].[ETLPackageExecutionHistory]
  (
     [ETLPackageExecutionId]             BIGINT IDENTITY(1, 1)
     ,[SSISDBExecutionId]                INT NOT NULL --Need this to keep these rows unique since the same package could be executed twice during a batch
     ,[ETLBatchId]                       INT NOT NULL
     ,[ETLPackageGroupId]                INT NULL
     ,[ETLPackageId]                     INT NOT NULL
     ,[StartDateTime]                    DATETIME2 NOT NULL
     ,[EndDateTime]                      DATETIME2 NULL
     ,[ExecutionDurationInMinutes] AS DATEDIFF(MINUTE, StartDateTime, EndDateTime)
     ,[ETLPackageExecutionStatusId]      INT NOT NULL
     ,[MissingSSISDBExecutablesEntryInd] BIT
     ,[ErrorMessage]                     VARCHAR(MAX) NULL
     ,[CreatedDate]                      DATETIME2 (7) CONSTRAINT [DF_ETLPackageExecution_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                      VARCHAR (50) CONSTRAINT [DF_ETLPackageExecution_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]                  DATETIME2 (7) CONSTRAINT [DF_ETLPackageExecution_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]                  VARCHAR (50) CONSTRAINT [DF_ETLPackageExecution_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLPackageExecution] PRIMARY KEY (ETLPackageExecutionId),
     CONSTRAINT [FK_ETLPackageExecution_ETLPackage] FOREIGN KEY ([ETLPackageId]) REFERENCES [cfg].ETLPackage([ETLPackageId]),
     CONSTRAINT [FK_ETLPackageExecution_ETLBatch] FOREIGN KEY ([ETLBatchId]) REFERENCES [cfg].[ETLBatch]([ETLBatchId]),
     CONSTRAINT [FK_ETLPackageExecution_ETLPackageExecutionStatus] FOREIGN KEY (ETLPackageExecutionStatusId) REFERENCES ref.ETLPackageExecutionStatus(ETLPackageExecutionStatusId),
     CONSTRAINT [AK_ETLPackageExecution_SSISDBExecutionId_ETLPackageId] UNIQUE (SSISDBExecutionId, ETLPackageId),
     CONSTRAINT [FK_ETLPackageExecution_ETLPackageGroup] FOREIGN KEY ([ETLPackageGroupId]) REFERENCES cfg.ETLPackageGroup([ETLPackageGroupId])
  )

GO

CREATE INDEX [IX_ETLPackageExecution_ETLPackageId]
  ON [log].[ETLPackageExecutionHistory] (ETLPackageId)

GO

CREATE INDEX [IX_ETLPackageExecution_ETLBatchId]
  ON [log].[ETLPackageExecutionHistory] (ETLBatchId)

GO

CREATE INDEX [IX_ETLPackageExecution_ETLPackageExecutionStatusId]
  ON [log].[ETLPackageExecutionHistory] (ETLPackageExecutionStatusId)

GO

CREATE INDEX [IX_ETLPackageExecution_ETLPackageGroupIdETLPackageId]
  ON [log].[ETLPackageExecutionHistory] (ETLPackageGroupId, ETLPackageId) 
