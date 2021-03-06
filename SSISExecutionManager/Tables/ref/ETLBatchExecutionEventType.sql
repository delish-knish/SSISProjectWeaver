﻿CREATE TABLE [ref].[ETLBatchExecutionEventType]
  (
     [ETLBatchExecutionEventTypeId] INT NOT NULL
     ,[ETLBatchExecutionEventType]  VARCHAR(50) NULL
     ,[CreatedDate]        DATETIME2 (7) CONSTRAINT [DF_ETLBatchExecutionEventType_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]        VARCHAR (50) CONSTRAINT [DF_ETLBatchExecutionEventType_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]    DATETIME2 (7) CONSTRAINT [DF_ETLBatchExecutionEventType_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]    VARCHAR (50) CONSTRAINT [DF_ETLBatchExecutionEventType_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLBatchEventType] PRIMARY KEY ([ETLBatchExecutionEventTypeId]),
  ) 
