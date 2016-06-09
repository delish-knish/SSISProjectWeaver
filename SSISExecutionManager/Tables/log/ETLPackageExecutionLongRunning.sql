CREATE TABLE [log].[ETLPackageExecutionLongRunning]
  (
     [LongRunningETLPackagesId]     INT IDENTITY(1, 1) NOT NULL
     ,[SSISDBExecutionId]           INT NOT NULL
     ,[ExecutionStartTime]          DATETIMEOFFSET(7) NOT NULL
     ,[AverageExecutionTimeMinutes] INT
     ,[CurrentExectionTimeMinutes]  INT
     ,[CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_LongRunningETLPackages_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                 VARCHAR (50) CONSTRAINT [DF_LongRunningETLPackages_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_LongRunningETLPackages] PRIMARY KEY ([LongRunningETLPackagesId])
  ) 
