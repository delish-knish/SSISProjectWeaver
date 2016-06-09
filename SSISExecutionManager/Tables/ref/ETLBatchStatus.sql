CREATE TABLE [ref].[ETLBatchStatus]
  (
     [ETLBatchStatusId] INT NOT NULL 
     ,[ETLBatchStatus]  VARCHAR(50) NULL
     ,[CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_ETLBatchStatus_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]     VARCHAR (50) CONSTRAINT [DF_ETLBatchStatus_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate] DATETIME2 (7) CONSTRAINT [DF_ETLBatchStatus_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser] VARCHAR (50) CONSTRAINT [DF_ETLBatchStatus_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL, 
    CONSTRAINT [PK_ETLBatchStatus] PRIMARY KEY ([ETLBatchStatusId]),
  ) 
