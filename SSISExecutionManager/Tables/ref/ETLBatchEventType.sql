CREATE TABLE [ref].[ETLBatchEventType]
  (
     [ETLBatchEventTypeId] INT NOT NULL
     ,[ETLBatchEventType]  VARCHAR(50) NULL
     ,[CreatedDate]        DATETIME2 (7) CONSTRAINT [DF_ETLBatchEventType_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]        VARCHAR (50) CONSTRAINT [DF_ETLBatchEventType_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]    DATETIME2 (7) CONSTRAINT [DF_ETLBatchEventType_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]    VARCHAR (50) CONSTRAINT [DF_ETLBatchEventType_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLBatchEventType] PRIMARY KEY ([ETLBatchEventTypeId]),
  ) 
