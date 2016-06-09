CREATE TABLE [ref].[ETLExecutionStatus]
  (
     [ETLExecutionStatusId] INT NOT NULL PRIMARY KEY
     ,[ETLExecutionStatus]  VARCHAR(50) NULL
     ,[CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_ETLExecutionStatus_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]       VARCHAR (50) CONSTRAINT [DF_ETLExecutionStatus_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]   DATETIME2 (7) CONSTRAINT [DF_ETLExecutionStatus_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]   VARCHAR (50) CONSTRAINT [DF_ETLExecutionStatus_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
  ) 
