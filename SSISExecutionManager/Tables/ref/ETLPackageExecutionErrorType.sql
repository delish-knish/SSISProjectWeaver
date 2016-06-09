CREATE TABLE [ref].[ETLPackageExecutionErrorType]
  (
     [ETLPackageExecutionErrorTypeId] INT NOT NULL
     ,[ETLPackageExecutionErrorType]  VARCHAR(50) NULL
     ,[CreatedDate]                   DATETIME2 (7) CONSTRAINT [DF_ETLPackageExecutionErrorType_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                   VARCHAR (50) CONSTRAINT [DF_ETLPackageExecutionErrorType_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]               DATETIME2 (7) CONSTRAINT [DF_ETLPackageExecutionErrorType_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]               VARCHAR (50) CONSTRAINT [DF_ETLPackageExecutionErrorType_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLPackageExecutionErrorType] PRIMARY KEY ([ETLPackageExecutionErrorTypeId]),
  ) 
