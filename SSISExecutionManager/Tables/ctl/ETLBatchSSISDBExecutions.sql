CREATE TABLE [ctl].[ETLBatchSSISDBExecutions]
  (
     [ETLBatchExecutionId]	INT NOT NULL
     ,[SSISDBExecutionId]	BIGINT NOT NULL
     ,[ETLPackageId]		INT NOT NULL
     ,[CreatedDate]			DATETIME2 (7) CONSTRAINT [DF_ETLBatchSSISDBExecutions_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]			VARCHAR (50) CONSTRAINT [DF_ETLBatchSSISDBExecutions_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]		DATETIME2 (7) CONSTRAINT [DF_ETLBatchSSISDBExecutions_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]		VARCHAR (50) CONSTRAINT [DF_ETLBatchSSISDBExecutions_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLBatchSSISDBExecutions] PRIMARY KEY ([ETLBatchExecutionId], [SSISDBExecutionId]),
     CONSTRAINT [FK_ETLBatchSSISDBExecutions_ETLPackage] FOREIGN KEY ([ETLPackageId]) REFERENCES ctl.ETLPackage([ETLPackageId]),
     CONSTRAINT [FK_ETLBatchSSISDBExecutions_ETLBatchId] FOREIGN KEY ([ETLBatchExecutionId]) REFERENCES ctl.[ETLBatchExecution]([ETLBatchExecutionId]),
  )

GO

CREATE INDEX [IX_ETLBatchSSISDBExecutions_ETLPackageId]
  ON [ctl].[ETLBatchSSISDBExecutions] (ETLPackageId) 

GO

CREATE INDEX [IX_ETLBatchSSISDBExecutions_SSISDBExecutionId] ON [ctl].[ETLBatchSSISDBExecutions] (SSISDBExecutionId)
