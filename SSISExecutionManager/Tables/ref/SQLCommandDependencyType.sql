CREATE TABLE [ref].[SQLCommandDependencyType]
  (
     [SQLCommandDependencyTypeId] INT NOT NULL
     ,[SQLCommandDependencyType]  VARCHAR(50) NULL
     ,[CreatedDate]                  DATETIME2 (7) CONSTRAINT [DF_SQLCommandDependencyType_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                  VARCHAR (50) CONSTRAINT [DF_SQLCommandDependencyType_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_SQLCommandDependencyType_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]              VARCHAR (50) CONSTRAINT [DF_SQLCommandDependencyType_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_SQLCommandDependencyType] PRIMARY KEY ([SQLCommandDependencyTypeId]),
  ) 
