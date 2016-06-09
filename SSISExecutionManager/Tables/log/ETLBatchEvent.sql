CREATE TABLE [log].[ETLBatchEvent]
  (
     [ETLBatchEventId]      BIGINT IDENTITY(1, 1)
     ,[ETLBatchEventTypeId] INT NOT NULL
     ,[ETLBatchId]          INT NOT NULL
     ,[ETLPackageId]        INT NULL
     ,[Description]         VARCHAR(MAX) NOT NULL
     ,[EventDateTime]       DATETIME2 NOT NULL
     ,[CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_ETLBatchEventId_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]         VARCHAR (50) CONSTRAINT [DF_ETLBatchEventId_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     CONSTRAINT [PK_ETLBatchEventId] PRIMARY KEY (ETLBatchEventId),
     CONSTRAINT [FK_ETLBatchEventId_ETLPackage] FOREIGN KEY ([ETLPackageId]) REFERENCES [ctl].ETLPackage([ETLPackageId]),
     CONSTRAINT [FK_ETLBatchEventId_ETLBatch] FOREIGN KEY ([ETLBatchId]) REFERENCES [ctl].ETLBatch([ETLBatchId]),
     CONSTRAINT [FK_ETLBatchEvent_ETLBatchEventType] FOREIGN KEY (ETLBatchEventTypeId) REFERENCES ref.ETLBatchEventType(ETLBatchEventTypeId),
  ) 
