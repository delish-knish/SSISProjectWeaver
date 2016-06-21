CREATE TABLE [log].[ETLBatchExecutionEvent]
  (
     [ETLBatchExecutionEventId]      BIGINT IDENTITY(1, 1)
     ,[ETLBatchExecutionEventTypeId] INT NOT NULL
     ,[ETLBatchExecutionId] INT NOT NULL
     ,[ETLPackageId]        INT NULL
     ,[Description]         VARCHAR(MAX) NOT NULL
     ,[EventDateTime]       DATETIME2 NOT NULL
     ,[CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_ETLBatchExecutionEventId_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]         VARCHAR (50) CONSTRAINT [DF_ETLBatchExecutionEventId_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     CONSTRAINT [PK_ETLBatchExecutionEventId] PRIMARY KEY ([ETLBatchExecutionEventId]),
     CONSTRAINT [FK_ETLBatchExecutionEventId_ETLPackage] FOREIGN KEY ([ETLPackageId]) REFERENCES [ctl].ETLPackage([ETLPackageId]),
     CONSTRAINT [FK_ETLBatchExecutionEventId_ETLBatch] FOREIGN KEY ([ETLBatchExecutionId]) REFERENCES [ctl].[ETLBatchExecution]([ETLBatchExecutionId]),
     CONSTRAINT [FK_ETLBatchExecutionEvent_ETLBatchEventType] FOREIGN KEY ([ETLBatchExecutionEventTypeId]) REFERENCES ref.[ETLBatchExecutionEventType]([ETLBatchExecutionEventTypeId]),
  ) 
