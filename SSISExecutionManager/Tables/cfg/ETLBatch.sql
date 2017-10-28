CREATE TABLE [cfg].[ETLBatch]
  (
     [ETLBatchId]                 INT IDENTITY(1, 1) NOT NULL
    ,[ETLBatchName]               VARCHAR(250) CONSTRAINT [DF_ETLBatch_ETLBatchtName] DEFAULT ('None given') NOT NULL
    ,[ETLBatchDescription]        VARCHAR(MAX) CONSTRAINT [DF_ETLBatch_ETLBatchDescription] DEFAULT ('None given') NOT NULL
    ,[MinutesBackToContinueBatch] INT CONSTRAINT [DF_ETLBatch_MinutesBackToContinueBatch] DEFAULT (2880) NOT NULL
    ,[SendBatchCompleteEmailInd]  BIT CONSTRAINT [DF_ETLBatch_SendBatchCompleteEmailInd] DEFAULT (1) NOT NULL
    ,[CreatedDate]                DATETIME2 (7) CONSTRAINT [DF_ETLBatch_CreatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[CreatedUser]                VARCHAR (50) CONSTRAINT [DF_ETLBatch_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
    ,[LastUpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_ETLBatch_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[LastUpdatedUser]            VARCHAR (50) CONSTRAINT [DF_ETLBatch_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLBatch] PRIMARY KEY ([ETLBatchId]),
  )

GO 
