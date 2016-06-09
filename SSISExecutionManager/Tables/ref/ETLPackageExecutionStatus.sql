CREATE TABLE [ref].[ETLPackageExecutionStatus]
  (
     [ETLPackageExecutionStatusId] INT NOT NULL 
     ,[ETLPackageExecutionStatus]  VARCHAR(50) NULL
     ,[CreatedDate]                DATETIME2 (7) CONSTRAINT [DF_ETLPackageExecutionStatus_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                VARCHAR (50) CONSTRAINT [DF_ETLPackageExecutionStatus_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_ETLPackageExecutionStatus_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]            VARCHAR (50) CONSTRAINT [DF_ETLPackageExecutionStatus_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL, 
    CONSTRAINT [PK_ETLPackageExecutionStatus] PRIMARY KEY ([ETLPackageExecutionStatusId]),
  ) 
