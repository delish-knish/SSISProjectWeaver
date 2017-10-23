CREATE TABLE [log].[ETLPackageExecutionError]
  (
     [ETLPackageExecutionErrorId]      BIGINT IDENTITY(1, 1)
     ,[SSISDBExecutionId]              INT NULL
     ,[SSISDBEventMessageId]           BIGINT NULL --nullable to allow for logging unexpected terminations
     ,[ETLBatchExecutionId]            INT NOT NULL
     ,[ETLPackageId]                   INT NOT NULL
     ,[ETLPackageGroupId]              INT NULL
     ,[ErrorDateTime]                  DATETIME2 NOT NULL
     ,[ErrorMessage]                   VARCHAR(MAX) NOT NULL
     ,[EmailNotificationSentDateTime]  DATETIME2 NULL
     ,[ETLPackageExecutionErrorTypeId] INT CONSTRAINT [DF_ETLPackageExecutionError_ETLPackageExecutionErrorType] DEFAULT (1) NOT NULL
     ,[ETLPackageRestartDateTime]      DATETIME2 NULL
     ,[CreatedDate]                    DATETIME2 (7) CONSTRAINT [DF_ETLPackageExecutionError_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                    VARCHAR (50) CONSTRAINT [DF_ETLPackageExecutionError_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]                DATETIME2 (7) CONSTRAINT [DF_ETLPackageExecutionError_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]                VARCHAR (50) CONSTRAINT [DF_ETLPackageExecutionError_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLPackageExecutionError] PRIMARY KEY (ETLPackageExecutionErrorId),
     CONSTRAINT [FK_ETLPackageExecutionError_ETLPackage] FOREIGN KEY ([ETLPackageId]) REFERENCES [cfg].ETLPackage([ETLPackageId]),
     CONSTRAINT [FK_ETLPackageExecutionError_ETLPackageGroup] FOREIGN KEY ([ETLPackageGroupId]) REFERENCES [cfg].ETLPackageGroup([ETLPackageGroupId]),
     CONSTRAINT [FK_ETLPackageExecutionError_ETLBatchExecution] FOREIGN KEY ([ETLBatchExecutionId]) REFERENCES [ctl].[ETLBatchExecution]([ETLBatchExecutionId]),
     --CONSTRAINT [AK_ETLPackageExecutionError_SSISDBExecutionId_SSISDBEventMessageId] UNIQUE (SSISDBExecutionId, SSISDBEventMessageId), Removed to allow for non SSISDB errors
     CONSTRAINT [FK_ETLPackageExecutionError_ETLPackageExecutionErrorType] FOREIGN KEY (ETLPackageExecutionErrorTypeId) REFERENCES ref.ETLPackageExecutionErrorType(ETLPackageExecutionErrorTypeId)
  )

GO

CREATE INDEX [IX_ETLPackageExecutionError_ETLPackageId]
  ON [log].[ETLPackageExecutionError] (ETLPackageId)

GO

CREATE INDEX [IX_ETLPackageExecutionError_ETLBatchId]
  ON [log].[ETLPackageExecutionError] ([ETLBatchExecutionId])

GO 
